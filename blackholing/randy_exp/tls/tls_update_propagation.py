#!/usr/bin/env python3
import math
from argparse import ArgumentParser
from typing import Union

import matplotlib.pyplot as plt
import mrtparse
import numpy as np
from mrtparse import BGP_MSG_T, BGP4MP_ST, MRT_T

from ipaddress import ip_network, IPv4Network, IPv6Network


class Interval(object):
    def __init__(self, start=-math.inf, end=math.inf):
        self.start = start
        self.end = end

    def __contains__(self, item):
        return self.start <= item <= self.end


def find_prefix(bgp_update, prefix: Union[IPv4Network | IPv6Network]):
    nlris = bgp_update['nlri']

    for nlri in nlris:
        nlri_pfx = nlri['prefix']
        nlri_len = nlri['length']

        nlri_net = ip_network(f'{nlri_pfx}/{nlri_len}')

        if nlri_net == prefix:
            return True

    return False


def parse_mrt(mrt_file: str, pfx: Union[IPv4Network | IPv6Network | str], local: bool,
              interval: Union[Interval | None] = None, collector_ip: str = None):

    if isinstance(pfx, str):
        pfx = ip_network(pfx)

    if local:
        st_cond = [BGP4MP_ST['BGP4MP_MESSAGE_LOCAL'],
                   BGP4MP_ST['BGP4MP_MESSAGE_LOCAL_ADDPATH'],
                   BGP4MP_ST['BGP4MP_MESSAGE_AS4_LOCAL'],
                   BGP4MP_ST['BGP4MP_MESSAGE_AS4_LOCAL_ADDPATH']]
    else:
        st_cond = [BGP4MP_ST['BGP4MP_MESSAGE'],
                   BGP4MP_ST['BGP4MP_MESSAGE_ADDPATH'],
                   BGP4MP_ST['BGP4MP_MESSAGE_AS4'],
                   BGP4MP_ST['BGP4MP_MESSAGE_AS4_ADDPATH']]

    updates_time = []

    for record in mrtparse.Reader(mrt_file):
        mrt_msg = record.data
        mrt_type = list(mrt_msg['type'])[0]
        mrt_subtype = list(mrt_msg['subtype'])[0]
        has_microsec = mrt_type == MRT_T['BGP4MP_ET']

        if mrt_subtype not in st_cond:
            continue

        bgp_msg = mrt_msg['bgp_message']
        bgp_type = list(bgp_msg['type'])[0]
        timestamp_s = int(list(mrt_msg['timestamp'].keys())[0])
        timestamp_micros = int(mrt_msg['microsecond_timestamp']) if has_microsec else 0

        peer_ip = mrt_msg['peer_ip']

        if bgp_type != BGP_MSG_T['UPDATE']:
            continue

        if interval is not None and timestamp_s not in interval:
            continue
        if collector_ip is not None and peer_ip != collector_ip:
            continue

        if find_prefix(bgp_msg, pfx):
            ts = timestamp_s * (10 ** 6)
            updates_time.append(ts + timestamp_micros)

    return updates_time


def get_cdf_points(data, bins=3000):
    c, cb = np.histogram(data, bins=bins)
    pdf = c / sum(c)
    cdf = np.cumsum(pdf)

    return cb[1:], cdf


def main(args):
    pfx = ip_network(args.prefix)

    # fixme hardcoded value
    interval = Interval(1706002108, math.inf)

    time_src = parse_mrt(args.src, pfx, True, interval)
    time_dst = parse_mrt(args.dst, pfx, False, interval)

    assert len(time_src) == len(time_dst), (f"Nb Updates mismatch: "
                                            f"Originated: {len(time_src)} != "
                                            f"Received: {len(time_dst)}")

    print(f"Updates seen: {len(time_src)}")

    delta = [(recv - send) / (10 ** 3) for recv, send in zip(time_dst, time_src)]
    x, y = get_cdf_points(delta, bins=4000)

    # plt.boxplot(delta, labels=('BGP-TLS Update\nPropagation',))
    plt.step(x, y, label='BGP-TLS Update\nPropagation')
    plt.legend(loc='best')
    plt.ylabel('CDF')
    plt.xlabel('Time (ms)')
    plt.grid()
    plt.xlim(xmin=x[0], xmax=x[-1])
    plt.show()


if __name__ == '__main__':
    parser = ArgumentParser(description="Parse the propagation time of the BGP update")

    parser.add_argument('-s', '--src', type=str, required=True,
                        help='Source .mrt file that sends the BGP update')
    parser.add_argument('-d', '--dst', type=str, required=True,
                        help='Destination .mrt file that receives the BGP update')
    parser.add_argument('-p', '--prefix', type=str, required=True,
                        help='The prefix we are interested to compute the update propagation')

    main(parser.parse_args())
