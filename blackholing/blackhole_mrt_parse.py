import argparse
import csv
import gzip
import json
import os
import typing
from argparse import ArgumentParser
from pathlib import Path
from typing import Union, TextIO

import mrtparse
from ipaddress import ip_network, IPv4Network, IPv6Network, ip_address, IPv4Address, IPv6Address

import numpy as np
from matplotlib import pyplot as plt
from tqdm import tqdm
from mrtparse import MRT_T, BGP4MP_ST, BGP_MSG_T, BGP_ATTR_T


def s2us(seconds: int):
    return seconds * 1e+6


def us2ms(microseconds: int) -> float:
    return microseconds / 1000


class Stats:
    def __init__(self) -> None:
        self.pfx_seen: dict[Union[IPv4Network, IPv6Network], list[
            tuple[Union[
                str, IPv4Address, IPv6Address], float]]] = {}  # dict key: pfx. value: list[src BGP speaker, timestamp]
        self.start_eor = -1
        self.errors = 0


def parse_nrli(data) -> list[IPv4Network | IPv6Network]:
    pfxs = []
    for nrli in data['nlri']:
        pfxs.append(ip_network(f"{nrli['prefix']}/{nrli['length']}"))

    return pfxs


def parse_mp_reach(data) -> list[IPv4Network | IPv6Network]:
    mp_reach = data['value']
    return parse_nrli(mp_reach)


def parse_bgp_message(data):
    if BGP_MSG_T['UPDATE'] not in data['type']:
        return None

    mp_reach = [attr for attr in data['path_attributes'] if BGP_ATTR_T['MP_REACH_NLRI'] in attr['type']]
    assert len(mp_reach) <= 1, "Wow! Several MP_REACH attr found in BGP Update"

    if any(mp_reach):
        prefixes = parse_mp_reach(mp_reach[0])
    else:
        prefixes = parse_nrli(data)

    return prefixes if len(prefixes) > 0 else None


def parse_BGP4MP(data, stats):
    if (BGP4MP_ST['BGP4MP_MESSAGE'] not in data['subtype'] and
            BGP4MP_ST['BGP4MP_MESSAGE_AS4'] not in data['subtype'] and
            BGP4MP_ST['BGP4MP_MESSAGE_LOCAL'] not in data['subtype'] and
            BGP4MP_ST['BGP4MP_MESSAGE_AS4_LOCAL'] not in data['subtype']):
        return False
    pfxs = parse_bgp_message(data['bgp_message'])
    if pfxs is None:
        return False

    for prefix in pfxs:
        timestamp = s2us(list(data['timestamp'].keys())[0]) + \
                    (data['microsecond_timestamp'] if 'microsecond_timestamp' in data else 0)
        new_entry = (ip_address(data['peer_ip']), us2ms(timestamp))

        try:
            stats.pfx_seen[prefix].append(new_entry)
        except KeyError:
            stats.pfx_seen[prefix] = [new_entry]


def store_results(data: dict, out_file_path: str):
    with gzip.open(out_file_path, 'wt', newline='') as csvfile:
        fieldnames = ['prefix', 'peer_ip', 'time']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

        writer.writeheader()
        for pfx, times in data.items():
            for peer_ip, time in times:
                writer.writerow({'prefix': str(pfx),
                                 'peer_ip': str(peer_ip),
                                 'time': float(time)})


def yield_times(stats: Stats):
    for pfx, times in stats.pfx_seen.items():
        if len(times) >= 2:
            latest = times[-1][1]
            for _, time in times[:-1]:
                yield latest - time


def parse_mrt_dump(mrt_path: str, out_store: Union[None, Path] = None):
    stats = Stats()
    tot_length = os.stat(mrt_path).st_size

    with tqdm.wrapattr(open(mrt_path, 'rb'), "read", total=tot_length) as mrt_file:
        rdr = mrtparse.Reader(mrt_file)

        for entry in rdr:
            if entry.err:
                stats.errors += 1
            elif (MRT_T['BGP4MP'] not in entry.data['type'] and
                  MRT_T['BGP4MP_ET'] not in entry.data['type']):
                pass
            else:
                parse_BGP4MP(entry.data, stats)

    print(f"Parsing done: {stats.errors} error(s).\n"
          f"Prefixes seen: {len(stats.pfx_seen)}.")

    if out_store:
        print("storing_results...")
        store_results(stats.pfx_seen, str(out_store))

    return stats

def info_from_prefix(stats: Stats, pfx: Union[IPv4Network, IPv6Network]):
    #print(stats.pfx_seen)
    try:
        pfx_info = stats.pfx_seen[pfx]
    except KeyError:
        return None

    # get the last update
    return pfx_info[-1]


def get_setup_time(prefix: str, directory: str,
                   from_rtr: str, to_rtr: str):
    results = {}
    directory = Path(directory)
    prefix = ip_network(prefix)

    from_mrts = list(directory.glob(from_rtr))
    to_mrts = list(directory.glob(to_rtr))

    for from_mrt, to_mrt in zip(from_mrts, to_mrts):
        for mrt, key in ((from_mrt, 'from'), (to_mrt, 'to')):
            iteration_nb = mrt.name.split('.')[-1]
            stats = parse_mrt_dump(str(mrt))
            info = info_from_prefix(stats, prefix)
            try:
                results[iteration_nb][key] = info
            except KeyError:
                results[iteration_nb] = {key: info}

    return [ vals['to'][-1] - vals['from'][-1] for _, vals in results.items() ]

    #fig2, ax2 = plt.subplots()
    #ax2.set_title('Blackholing setup Time (ms)')
    #ax2.boxplot(setup_time)

    #plt.show()

    #print(setup_time)


def main(conf: dict):
    data_plot = []
    x_labels = []

    for exp in conf['exps']:
        data_plot.append(get_setup_time(prefix=conf['prefix'], directory=exp['dir'],
                       from_rtr=exp['from'], to_rtr=exp['to']))
        x_labels.append(exp['name'])

    plt.figure(figsize=(3,2))
    plt.boxplot(data_plot, widths=0.7)
    plt.xticks([i for i in range(1, len(x_labels)+1)], x_labels)
    plt.ylabel("Time (ms)")
    #plt.title("Blackholing setup time")

    axes = plt.axes([.49, .47, .40, .40])

    #inset_ax = plt.inset_axes([0.2, 0.6, 0.2, 0.2])
    axes.boxplot(data_plot, showfliers=False)
    axes.set_xticklabels(x_labels)
    #axes.xticks([i for i in range(1, len(x_labels)+1)], x_labels)

    plt.grid(visible=True, which='both')
    #plt.tight_layout()
    plt.show()




if __name__ == '__main__':
    config = {
        'prefix': '1.1.1.1/32',
        'exps': [
            {'from': 'node001.updates.mrt.*',
             'to': 'node005.updates.mrt.*',
             'dir': '/home/thomas/Bureau/exps/blackhole/exps_full/tcp',
             'name': 'Classic\nRTBH'},
            {'from': 'node001.updates.mrt.*',
             'to': 'node005.updates.mrt.*',
             'dir': '/home/thomas/Bureau/exps/blackhole/exps_full/quic',
             'name': 'Secure\nRTBH'}
        ]
    }

    #parser = argparse.ArgumentParser("Get black-holing setup time")
    #parser.add_argument('-c', '--config', dest='config', type=str, required=True,
    #                    help='Config')

    main(config)
