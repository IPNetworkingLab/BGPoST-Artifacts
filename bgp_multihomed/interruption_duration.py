#!/usr/bin/env python3

from argparse import ArgumentParser
from pathlib import Path
from typing import TextIO, Iterable, Sequence

import ijson
import matplotlib.pyplot as plt

from bgp_multihomed.parse_bw_pcapng import process_data


def handle_data(f: TextIO):
    data = {}
    for record in ijson.items(f, 'item'):
        layers = record['_source']['layers']
        interface_name = layers['frame.interface_name'][0]
        time = float(layers['frame.time_epoch'][0])

        try:
            # only update end time
            data[interface_name]['end'] = time
        except KeyError:
            data[interface_name] = {
                'start': time,
                'end': time
            }
    return data


def get_interruption(data: dict):
    start = max([value['start'] for _, value in data.items()])
    end = min([value['end'] for _, value in data.items()])

    return start - end


def process_pcap(pcap_file: str):
    fields = ['frame.interface_name', 'frame.protocols',
              'frame.time_epoch', 'ip.src', 'ip.dst']

    filters = ['iperf3 and ip.addr == 42.42.42.42']

    data = process_data(pcap_file, handle_data, fields, filters)
    down_time = get_interruption(data)

    return down_time


def get_down_times(directory: str):
    times = []

    directory = Path(directory)
    pcaps = directory.glob('*.pcapng')

    for pcap in pcaps:
        time = process_pcap(str(pcap))
        times.append(time * (10 ** 3))

    return times


def do_boxplot(data: Sequence[list], exp_names: Sequence[str]):
    plt.boxplot(data, labels=exp_names, vert=False, widths=[2 for _ in range(len(data))])
    plt.grid()
    plt.xlabel('Downtime duration (ms)')
    plt.show()


def parse_str_exp(exp: str):
    if ',' not in exp:
        raise SyntaxError('Arg must be <path>,<exp_name>')

    arr_split = exp.split(',')

    if len(arr_split) != 2:
        raise SyntaxError('Arg must be <path>,<exp_name>')

    return arr_split[0], arr_split[1]


def main(args):
    data = []
    names = []

    for exp in args.exps:
        path, exp_name = parse_str_exp(exp)

        data.append(get_down_times(path))
        names.append(exp_name)

    do_boxplot(data, names)


if __name__ == '__main__':
    parser = ArgumentParser(description="Get Down time")

    parser.add_argument('-e', '--exps', required=True,
                        action='append',
                        help="Directories containing pcapng files")

    main(parser.parse_args())
