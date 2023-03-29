#!/usr/bin/env python3
import argparse
import csv
from typing import Iterable

import matplotlib.pyplot as plt

from benchmarks.mrtparser import get_cdf_data, plot_show


def get_request_completion(tsv_files: Iterable[str]):
    completion_times = []
    wait_times = []

    for tsv_file in tsv_files:
        with open(tsv_file) as f:
            rd = csv.DictReader(f, delimiter='\t', quotechar='"')
            for row in rd:
                completion_times.append(int(row['ttime']))
                wait_times.append(int(row['wait']))

    return completion_times, wait_times


def main(args):
    for exp_files, type_str, linestyle in ((args.tsv_dual, 'Dual', '-.'), (args.tsv, 'Single', '-')):
        completion_time, latency_time = get_request_completion(exp_files)

        # x_c, y_c = get_cdf_data(completion_time)
        x_l, y_l = get_cdf_data(latency_time)

        # plt.plot(x_c, y_c, label=f'Total Request Time ({type_str})')
        plt.plot(x_l, y_l, label=f'{type_str}',
                 linestyle=linestyle)

    plot_show('Service Latency Response Duration (ms)', None, False)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    parser.add_argument('--tsv', dest='tsv', nargs='+', type=str, required=True,
                        help="tsv file to parse on single server")

    parser.add_argument('--tsv-dual', dest='tsv_dual', nargs='+', type=str,
                        required=True, help='tsv on dual server')

    main(parser.parse_args())
