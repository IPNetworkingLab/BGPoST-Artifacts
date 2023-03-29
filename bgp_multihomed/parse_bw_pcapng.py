#!/usr/bin/env python3
import os
import shutil
import subprocess
import threading
from argparse import ArgumentParser
from typing import TextIO, Union

import ijson
import matplotlib.pyplot as plt


def do_wait(proc: subprocess.Popen, write_pipe):
    proc.wait()
    os.close(write_pipe)


def process_data(pcapng: str, processor: callable, fields: list[str],
                 filters: Union[None | list[str]] = None):
    if filters is None:
        filters = []
    r, w = os.pipe()
    tshark = shutil.which('tshark')
    if tshark is None:
        raise ValueError('tshark not found')

    tshark_fields = []
    for field in fields:
        tshark_fields.append('-e')
        tshark_fields.append(field)

    for t_filter in filters:
        tshark_fields.append(t_filter)

    cmd = [tshark, '-r', pcapng, '-T', 'json']
    cmd.extend(tshark_fields)

    tsh_p = subprocess.Popen(cmd, shell=False, stdout=w)
    thread = threading.Thread(target=do_wait, args=(tsh_p, w))
    thread.start()

    with open(r, 'r', encoding='utf-8') as f:
        data = processor(f)
    thread.join()
    return data


def handle_data_builder(ip_src, ip_dst) -> callable:
    def handle_data(f: TextIO):
        data = {}
        for record in ijson.items(f, 'item'):
            layers = record['_source']['layers']

            interface_name = layers['frame.interface_name'][0]
            time = float(layers['frame.time_epoch'][0])
            frame_len = int(layers['frame.len'][0])
            protocols = layers['frame.protocols'][0]

            if 'iperf3' not in protocols:
                continue

            point = {
                'time': time,
                'length': frame_len * 8
            }

            try:
                data[interface_name].append(point)
            except KeyError:
                data[interface_name] = [point]
        return data

    return handle_data


def cumul_bits(data, interval):
    base_time = data[0]['time']
    end_time = base_time + interval
    nb_bits = 0
    nb_points_consumed = 0

    for point in data:
        if point['time'] > end_time:
            break
        nb_bits += point['length']
        nb_points_consumed += 1

    return nb_points_consumed, nb_bits


def process_interval(data: list, min_time, max_time):
    nb_bits = 0
    nb_consumed = 0
    for point in data:
        if point['time'] < min_time:
            break
        if point['time'] > max_time:
            break
        nb_bits += point['length']
        nb_consumed += 1

    return nb_consumed, nb_bits


def compute_bw2(points: list, interval: float = 1, start_time=None, end_time=None):
    data = []
    if start_time is None:
        start_time = 0  # points[0]['time']
    if end_time is None:
        end_time = points[-1]['time']
    curr_iv = start_time
    i = 0
    points_len = len(points)

    while curr_iv < end_time:
        if i >= points_len:
            data.append((curr_iv, 0))
        else:
            nb_points, bits = process_interval(points[i:], curr_iv, curr_iv + interval)
            bps = bits * (1 / interval)
            data.append((curr_iv, bps))
            i += nb_points

        curr_iv += interval

    return data


def compute_bw(points: list, interval: float = 1):
    start_time = points[0]['time']
    points_len = len(points)
    data = []
    i = 0
    while i < points_len:
        nb_points, bits = cumul_bits(points[i:], interval)
        bps = bits * (1 / interval)
        time = points[i]['time']
        data.append((time - start_time, bps))
        i += nb_points

    return data


def find_max_time(data):
    max_time = -1
    for interface in data:
        end_time = data[interface][-1]['time']
        if end_time > max_time:
            max_time = end_time
    return max_time


def find_min_time(data):
    min_time = None
    for interface in data:
        start_time = data[interface][0]['time']
        if min_time is None:
            min_time = start_time
        elif start_time < min_time:
            min_time = start_time
    return min_time


def plot_data(data: dict, interval: float = 1):
    max_end_time = find_max_time(data)
    min_start_time = find_min_time(data)

    for interface in data:
        bw = compute_bw2(data[interface], interval, min_start_time, max_end_time)
        plt.step([x - min_start_time for x, _ in bw],
                 [y / (10 ** 6) for _, y in bw],
                 label=interface)
    plt.legend(loc='best')
    plt.ylabel('Estimated Bandwidth (Mbps)')
    plt.xlabel('Time (s)')
    plt.grid()
    plt.tight_layout()
    plt.show()


def main(args):
    tshark_processor = handle_data_builder(None, None)

    fields = ['frame.interface_name', 'frame.protocols',
              'frame.len', 'frame.time_epoch', 'ip.src', 'ip.dst']

    raw_data = process_data(args.pcap, tshark_processor, fields)
    plot_data(raw_data, args.interval)


if __name__ == '__main__':
    parser = ArgumentParser(description='Parse bandwidth pcap')
    parser.add_argument('-f', '--file', dest='pcap', required=True,
                        help="Pcap file to parse")
    parser.add_argument('-i', '--interval', dest='interval', type=float,
                        required=False, default=1.0, help='Group data per interval in second')

    main(parser.parse_args())
