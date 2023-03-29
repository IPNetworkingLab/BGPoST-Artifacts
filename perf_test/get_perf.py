#!/usr/bin/env python3
import csv
import os
import pickle
from argparse import ArgumentParser
from multiprocessing import Pool
from pathlib import Path

import matplotlib.pyplot as plt

from benchmarks.mrtparser import Stats, parse_mrt_dump, get_cdf_data


def compute_propagation_time(exp: str, in_mrt: str, out_mrt: str):
    stats = Stats()

    parse_mrt_dump(in_mrt, stats)
    parse_mrt_dump(out_mrt, stats)

    # per_prefix_time = [records[-1][1] - records[0][1] for pfx, records in stats.pfx_seen.items() if len(records) > 1]
    convergence_time = stats.max_time - stats.min_time

    # print(f"[Info] Prefixes propagated {len(per_prefix_time)}")

    return exp, convergence_time  # , per_prefix_time


def compute_convergence(exps: str):
    data = {}
    base_path = Path(exps).parent

    exp_to_parse = []

    with open(exps, newline='') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            path_in = base_path.joinpath(Path(row['input']))
            path_out = base_path.joinpath(Path(row['output']))
            exp_type = row['experiment']

            exp_to_parse.append((exp_type, str(path_in), str(path_out)))

    async_tasks = []
    available_cores = len(os.sched_getaffinity(0))

    with Pool(available_cores) as p:
        for exp_args in exp_to_parse:
            async_tasks.append(p.apply_async(compute_propagation_time, args=exp_args))

        for async_task in async_tasks:
            async_task.wait()
            ext_type, convergence = async_task.get()

            point = {
                'convergence': convergence
            }

            try:
                data[ext_type].append(point)
            except KeyError:
                data[ext_type] = [point]

    return data


def reassemble_data(data_exps: dict):
    convergence_times = []
    for exp_type, data_type in data_exps.items():
        # all_times = [item for lst in data_type for item in lst['per_pfx_propagation']]
        convergences = [exp['convergence'] for exp in data_type]

        convergence_times.append((exp_type, convergences))
        # x, y = get_cdf_data(all_times)
        # plt.step(x, y, label=exp_type)
    with open("convergences_times.pickle", 'wb') as f:
        pickle.dump(convergence_times, f)

    return convergence_times


def pretty_label(label: str):
    label = label.upper()
    label = label.replace('_', '-')
    return label


def plot_results(convergence_times: list):
    # compute box plot
    plt.boxplot([[time / (10 ** 6) for time in times] for _, times in convergence_times],
                labels=[pretty_label(label) for label, _ in convergence_times])
    plt.ylabel("Convergence Time (s)")
    plt.grid()
    plt.ylim((6.0, 11))
    plt.tight_layout()
    plt.show()
    plt.savefig('convergence_time.pdf')


def main(args):
    if args.pickle:
        if not Path(args.pickle).exists():
            raise FileNotFoundError(args.pickle)

        with open(args.pickle, 'rb') as f:
            bp_data = pickle.load(f)
    else:
        data = compute_convergence(args.input)
        bp_data = reassemble_data(data)

    plot_results(bp_data)


if __name__ == '__main__':
    parser = ArgumentParser(description='Convergence time for two BGP routers')
    m_group = parser.add_mutually_exclusive_group(required=True)

    m_group.add_argument('-i', '--input', required=False, type=str,
                         help='Path to the csv file containing experiments to parse')
    m_group.add_argument('-p', '--pickle', required=False, type=str,
                         help='Pickle containing parsed data from previous run')

    main(parser.parse_args())
