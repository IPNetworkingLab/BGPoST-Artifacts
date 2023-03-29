#!/usr/bin/env python3
import datetime
import math
import statistics
import sys
from pathlib import Path
from typing import Iterable

import ijson
import numpy as np
import scipy.stats as st


def get_path_change_time(exps_dir_json: Path) -> Iterable:
    glob = exps_dir_json.glob("./node1.*.json")

    path_change_time = []

    for exp in glob:
        with open(str(exp), 'r') as f:
            start_time = None
            end_time = None
            for record in ijson.items(f, 'item'):
                curr_time = float(record['_source']['layers']['frame.time_relative'][0])
                udp_length = int(record['_source']['layers']['udp.length'][0])
                if 1200 <= udp_length <= 1250:
                    # trust me, this is path challenge and path response payload size
                    end_time =  curr_time
                    if start_time is None:
                        start_time = curr_time

            path_change_time.append(end_time - start_time)

    return path_change_time


def get_lsa_convergence(exps_dir_logs: Path) -> Iterable:
    glob_client = exps_dir_logs.glob("./node1.*.log")
    glob_server = exps_dir_logs.glob("./node2.*.log")

    res = {}
    convergence_time = []

    for curr_glob, node_type in ((glob_client, 'client'), (glob_server, 'server')):
        for exp in curr_glob:
            with open(str(exp), 'r') as f:
                exp_number = int(exp.name.split('.')[-2])
                for line in f.readlines():
                    if ((node_type == 'client' and 'PtP to Down' in line) or
                            (node_type == 'server' and 'replaced' in line)):
                        s_line = line.strip().split(' ')
                        datetime_str = s_line[1]
                        dt = datetime.datetime.strptime(datetime_str, "%H:%M:%S.%f")

                        try:
                            res[exp_number][node_type] = dt.timestamp()
                        except KeyError:
                            res[exp_number] = {node_type: dt.timestamp()}

    # now compute time
    for key, value in res.items():
        convergence_time.append(value['server'] - value['client'])

    return convergence_time


def medianCI(data, ci, p = 0.5):
    '''
    data: pandas datafame/series or numpy array
    ci: confidence level
    p: percentile' percent, for median it is 0.5
    output: a list with two elements, [lowerBound, upperBound]
    '''

    data = np.sort(data)
    N = data.shape[0]

    lowCount, upCount = st.binom.interval(ci, N, p, loc=0)
    # given this: https://onlinecourses.science.psu.edu/stat414/node/316
    # lowCount and upCount both refers to  W's value, W follows binomial Dis.
    # lowCount need to change to lowCount-1, upCount no need to change in python indexing
    lowCount -= 1
    # print lowCount, upCount

    return np.median(data),  data[int(upCount)] - np.median(data)


def median_confidence_interval(dx,confidence=.95):
    m = np.median(dx)
    s = np.std(dx)
    dof = len(dx) -1

    t_crit = np.abs(st.t.ppf((1 - confidence) / 2, dof))

    low, hi = (m - s * t_crit / np.sqrt(len(dx)), m + s * t_crit / np.sqrt(len(dx)))

    return m, m-low

def get_confidence_interval(data: list, int_val: float):
    assert 0 < int_val < 1
    return median_confidence_interval(data, int_val)


def main(exp_type: str, out_dir: Path):
    if exp_type == 'tshark':
        times = get_path_change_time(out_dir)
    elif exp_type == 'logs':
        times = get_lsa_convergence(out_dir)
    else:
        raise ValueError(f'Type {exp_type} not supported: Either "tshark" or "logs"')

    print(get_confidence_interval(times, 0.99))


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(f'Usage: {sys.argv[0]} <tshark|logs> <OUT_DIR>')
        exit(1)

    exp_type_ = sys.argv[1]
    exps_dir = Path(sys.argv[2])

    main(exp_type_, exps_dir)
