#!/usr/bin/env python3
import argparse
import json
from typing import Iterable

import matplotlib.pyplot as plt

from benchmarks.mrtparser import plot_show


def parse_log(log_file: str, latency_distrib: dict):
    cumul_response = 0

    with open(log_file, 'r') as f:
        data = json.load(f)

    total_response = data['totalSuccessCodes']

    for point in data['latencyDistribution']:
        curr_point = point['count']
        curr_ms = point['latencyMs']
        cumul_response += curr_point

        try:
            latency_distrib[curr_ms] += curr_point
        except KeyError:
            latency_distrib[curr_ms] = curr_point

    # safe check
    assert cumul_response == total_response, \
        f'Nb responses mismatch: parsed: {cumul_response}. expected: {total_response}'

    return cumul_response


def parse_logs(logs_file: Iterable):
    distribution = {}

    total_queries = 0
    cumul_queries = 0

    for log_file in logs_file:
        print(f"Parsing {log_file}")
        total_queries += parse_log(log_file, distribution)

    return [(ms, (cumul_queries := (cumul_queries + cnt)) / total_queries)
            for ms, cnt in distribution.items() if cnt > 0]


def make_plot(x, y, label: str, linestyle: str = '-'):
    plt.step(x, y, label=label, linestyle=linestyle)


def main(args):
    for exp, name, linestyle in ((args.single, "Single", '-'),
                                 (args.dual, "Dual", '-.')):
        data_plot = parse_logs(exp)
        make_plot(
            [x for x, _ in data_plot],
            [y for _, y in data_plot],
            name,
            linestyle
        )

    plot_show('DNS Response Latency (ms)', None, False)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Parse dns latency log")

    parser.add_argument('-s', '--single', required=True, type=str, nargs='+',
                        help='log file of dnspyre single experiment to parse')
    parser.add_argument('-d', '--dual', required=True, type=str, nargs='+',
                        help='log file of dnspyre dual experiment to parse')

    main(parser.parse_args())
