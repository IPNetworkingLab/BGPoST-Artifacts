#!/usr/bin/env python3
import csv
import pickle
from argparse import ArgumentParser
from pathlib import Path
from typing import TextIO

import ijson
import matplotlib.pyplot as plt
import mrtparse

from mrtparse.params import MRT_T, BGP4MP_ST, BGP_MSG_T, BGP_ATTR_T

from bgp_multihomed.parse_bw_pcapng import process_data


def is_eor_update(bgp_data):
    bgp_msg_t = (BGP_MSG_T['UPDATE'],)

    if list(bgp_data['type'].keys())[0] not in bgp_msg_t:
        return False

    mp_reach = [attr for attr in bgp_data['path_attributes'] if BGP_ATTR_T['MP_REACH_NLRI'] in attr['type']]
    assert len(mp_reach) <= 1, "Malformed BGP Message. More than one MP_REACH_NLRI found"

    if len(mp_reach) == 1:
        nlris = mp_reach[0]['value']['nrli']
    else:
        nlris = bgp_data['nlri']
    return len(nlris) == 0


def is_eor_from_mrt(data):
    bgp_st = (BGP4MP_ST['BGP4MP_MESSAGE'],
              BGP4MP_ST['BGP4MP_MESSAGE_AS4'],
              BGP4MP_ST['BGP4MP_MESSAGE_AS4_ADDPATH'],
              BGP4MP_ST['BGP4MP_MESSAGE_ADDPATH'])

    if list(data['subtype'].keys())[0] not in bgp_st:
        return False
    return is_eor_update(data['bgp_message'])


def get_timestamp(data):
    ts = (list(data['timestamp'].keys())[0]) * (10 ** 6)
    ts_micro = data['microsecond_timestamp'] if 'microsecond_timestamp' in data else 0
    return ts + ts_micro


def get_first_eor(mrt_dump: str, peer_ip: str):
    errors = 0

    bgp_mp = (MRT_T['BGP4MP'], MRT_T['BGP4MP_ET'])

    with open(mrt_dump, 'rb') as f:
        rdr = mrtparse.Reader(f)

        for entry in rdr:
            if entry.err:
                errors += 1
            elif list(entry.data['type'].keys())[0] not in bgp_mp:
                pass
            elif entry.data['peer_ip'] != peer_ip:
                pass
            elif is_eor_from_mrt(entry.data):
                return get_timestamp(entry.data)


def tshark_processor_builder(ip_src: str) -> callable:
    def tshark_processor(f: TextIO):
        tcp_syn_seen = []
        for record in ijson.items(f, 'item'):
            layers = record['_source']['layers']
            time = float(layers['frame']['frame.time_epoch'])
            thsark_ip_src = layers['ip']['ip.src']

            if thsark_ip_src == ip_src:
                time_micro = int(time * (10 ** 6))
                tcp_syn_seen.append(time_micro)

        assert len(tcp_syn_seen) > 0
        return tcp_syn_seen

    return tshark_processor


def parse_pcap(pcapng: str, processor: callable, ip_src: str, tcp: bool):
    fields = []  # do not filter fields to retrieve from tshark
    if tcp:
        filters = [f'tcp.flags==0x002 and ip.src=={ip_src}']
    else:
        filters = [f'quic.long.packet_type == 0 and ip.src == {ip_src}']

    return process_data(pcapng, processor, fields, filters)


def handle_experiment(pcapng: str, rtr2_mrt: str, processor: callable, ip_src: str):
    pcap_name = Path(pcapng).name
    tcp = False if 'quic' in pcap_name else True

    handshake_time = parse_pcap(pcapng, processor, ip_src, tcp)
    eor_time = get_first_eor(rtr2_mrt, ip_src)

    assert len(handshake_time) == 1
    return eor_time - handshake_time[0]


def get_experiments_to_parse(exps_csv: str):
    exps = []
    file_dir_path = Path(exps_csv).parent
    with open(exps_csv) as f:
        reader = csv.DictReader(f)

        for record in reader:
            exp_type = record['experiment']
            pcapng = str(file_dir_path.joinpath(record['tshark']))
            mrt_eor = str(file_dir_path.joinpath(record['handshake']))
            exps.append((exp_type, pcapng, mrt_eor))

    return exps


def handle_experiments(exps_csv, ip_src: str):
    exp_data = {}

    exps = get_experiments_to_parse(exps_csv)
    my_processor = tshark_processor_builder(ip_src)

    for exp_type, pcap_file, mrt_file in exps:
        print(f'Processing {pcap_file} and {mrt_file}')
        handshake_time = handle_experiment(pcap_file, mrt_file, my_processor, ip_src)

        try:
            exp_data[exp_type].append(handshake_time)
        except KeyError:
            exp_data[exp_type] = [handshake_time]

    with open('handshake_data.pickle', 'wb') as f:
        pickle.dump(exp_data, f)

    return exp_data


def pretty(label: str):
    label = label.upper()
    label = label.replace('_', '-')
    return label


def plot_data(exp_data: dict):
    x_times = []
    y_labels = []
    x_quic = []

    fig, (ax1, ax2) = plt.subplots(1, 2)

    for exp, times in exp_data.items():
        if exp == 'quic':
            x_quic = [time / 1000 for time in times]
        x_times.append([time / 1000 for time in times])
        y_labels.append(pretty(exp))

    ax1.boxplot(x_times, labels=y_labels)
    ax1.grid()
    ax1.set_ylabel('BGP Handshake Duration (ms)')
    ax1.set_ylim((70, 90))

    ax2.boxplot(x_quic, labels=('QUIC',))
    ax2.grid()

    plt.tight_layout()
    plt.show()
    plt.savefig('handshake_time.pdf')


def main(args):
    if args.pickle:
        with open(args.pickle, 'rb') as f:
            exp_data = pickle.load(f)
    elif not args.ip_src:
        print('--ip_src is required!')
        exit(1)
    else:
        exp_data = handle_experiments(args.csv, args.ip_src)

    plot_data(exp_data)


if __name__ == '__main__':
    parser = ArgumentParser(description="Compute the handshake time to establish a BGP session")
    m_group = parser.add_mutually_exclusive_group(required=True)
    m_group.add_argument('-c', '--csv', required=False, type=str,
                         help='CSV containing the experiments made')
    m_group.add_argument('-p', '--pickle', required=False, type=str,
                         help='Pickle data of processed data')

    parser.add_argument('-s', '--ip-src', dest='ip_src', required=False, type=str,
                        help="Src IP that initiate the BGP connection")

    main(parser.parse_args())
