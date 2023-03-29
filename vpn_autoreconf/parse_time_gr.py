#!/usr/bin/env python3
import re
from argparse import ArgumentParser
from datetime import datetime
from pathlib import Path
from typing import Iterable

import matplotlib.pyplot as plt


def find_date_reconfig(logs: str, pattern: str, id_group: int):
    match = re.search(pattern, logs, re.MULTILINE)
    if match is None:
        return None

    time = match.group(id_group)
    return datetime.strptime(time, "%H:%M:%S.%f")


def find_50mbit_reconfig(logs: str):
    print()
    return find_date_reconfig(logs,
                              r"qdisc tbf.*50Mbit.*(\r\n?|\n)+.*(\d{2}:\d{2}:\d{2}.\d{6}).*Reconfiguration.*succeeded",
                              2)


def find_gr_done_client(logs: str):
    return find_date_reconfig(logs,
                              r"(\d{1,2}:\d{2}:\d{2}.\d{3}) <INFO> Shutting down for graceful restart",
                              1)


def find_gr_done_provider(logs: str):
    return find_date_reconfig(logs,
                              r"(\d{1,2}:\d{2}:\d{2}.\d{3}) <TRACE>.*Neighbor graceful restart done",
                              1)


def get_data(data: dict, files: Iterable[Path], date_finder: callable, sample_type: str):
    for file in files:
        exp_id = int(file.name.split('.')[-2])
        with open(str(file)) as f:
            date = date_finder(f.read())

        if date is None:
            print(f"Failed to parse {str(file)}")

        try:
            data[exp_id][sample_type] = date
        except KeyError:
            data[exp_id] = {sample_type: date}


def get_gr_time(data_points: dict):
    time = []

    for _, exp in data_points.items():
        start_gr: datetime = exp['client']
        end_gr: datetime = max(exp['ctrl_serv'], exp['provider']) if 'ctrl_serv' in exp else exp['provider']

        tdelta = end_gr - start_gr
        time.append(tdelta.total_seconds())

    return time


def main(args):
    exp_dir_tls = Path(args.dir_tls)
    exp_dir_tcp = Path(args.dir_tcp)
    data_point_tls = {}
    data_point_tcp = {}

    to_parse_tls = [
        (exp_dir_tls.glob("ce1.*.log"), find_gr_done_client, 'client'),
        (exp_dir_tls.glob("pe1.[0-9]*.log"), find_gr_done_provider, 'provider'),
        (exp_dir_tls.glob("pe1.ctrl_serv.*.log"), find_50mbit_reconfig, 'ctrl_serv')
    ]

    to_parse_tcp = [
        (exp_dir_tcp.glob("ce1.*.log"), find_gr_done_client, 'client'),
        (exp_dir_tcp.glob("pe1.[0-9]*.log"), find_gr_done_provider, 'provider')
    ]

    for parse in to_parse_tls:
        get_data(data_point_tls, *parse)

    for parse in to_parse_tcp:
        get_data(data_point_tcp, *parse)

    times_tls = get_gr_time(data_point_tls)
    times_tcp = get_gr_time(data_point_tcp)

    plt.boxplot((times_tcp, times_tls), labels=("Graceful Restart\n (TCP Baseline)",
                                                "Graceful Restart &\nShaping (TLS)"), vert=False)
    plt.xlabel("Time (s)")
    plt.grid()
    plt.show()


if __name__ == '__main__':
    parser = ArgumentParser(description='Parse graceful restart time + QoS')
    parser.add_argument('-t', '--dir-tcp', dest="dir_tcp", required=True, type=str,
                        help='Directory that contains the logs to parse (TCP experiment)')
    parser.add_argument('-u', '--dir-tls', dest="dir_tls", required=True, type=str,
                        help='Directory that contains the logs to parse (TLS experiment)')

    main(parser.parse_args())
