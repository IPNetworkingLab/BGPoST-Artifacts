#!/usr/bin/env python3
import math
import os
import pickle
from argparse import ArgumentParser
from multiprocessing import Pool
from pathlib import Path
from zoneinfo import ZoneInfo

import matplotlib.pyplot as plt
from tqdm import tqdm

from blackholing.randy_exp.tls.tls_update_propagation import parse_mrt, Interval

from datetime import datetime, timedelta


def parse_mrts(mrts_dir: str, collector_ip: str, target_pfx: str, interval: Interval):
    mrts_dir = Path(mrts_dir)
    mrts_glob = mrts_dir.glob('**/updates.*')
    mrts = [x for x in mrts_glob if x.is_file()]

    async_tasks = []
    available_cores = len(os.sched_getaffinity(0))
    data_times = []

    with Pool(available_cores) as p:
        for mrt in mrts:
            async_tasks.append(p.apply_async(parse_mrt,
                                             args=(str(mrt), target_pfx, False, interval, collector_ip)))

        for async_task in tqdm(async_tasks):
            async_task.wait()
            curr_times = async_task.get()
            if len(curr_times) > 0:
                curr_times.sort()
                data_times.append(curr_times[0])

    data_times.sort()
    return data_times


def filter_spurious_update(times: list, programed_upd_time: list[timedelta], margin_error: int):
    """
    !! programed_upd_time: list timedelta must be in UTC !!
    """
    filtered_times = []
    delta_error = timedelta(0, margin_error)
    ivs = [(x - delta_error, x + delta_error) for x in programed_upd_time]
    for c_time in times:
        # Work in UTC
        d_time = datetime.fromtimestamp(c_time / (10 ** 6), tz=ZoneInfo('UTC'))
        hms = d_time.time()
        hms.utcoffset()
        thms = timedelta(hours=hms.hour, minutes=hms.minute, seconds=hms.second)
        in_interval = False
        for iv_min, iv_max in ivs:
            if iv_min <= thms <= iv_max:
                in_interval = True
        if in_interval:
            filtered_times.append(c_time)
    return filtered_times


def main(args):
    # Fixme Hardcoded value
    # [ (2024/01/19 @18h30 UTC); inf [
    interval = Interval(start=1705689000)

    programed_time = [timedelta(0, 0, 0, 0, 30, x) for x in range(2, 24, 4)]

    send_times = parse_mrt(args.src_mrt, args.pfx, True, interval)

    recv_times = parse_mrts(args.dir,
                            args.collector,
                            args.pfx,
                            interval)
    recv_times = filter_spurious_update(recv_times, programed_time, 60)

    print(recv_times)

    assert len(recv_times) == len(send_times), ('BGP UPDATE length mismatch. '
                                                f'Send: {len(send_times)}. Recv: {len(recv_times)}')

    delta = [(recv - send) / (10 ** 3) for send, recv in zip(send_times, recv_times)]

    with open('bgp_tcp_beacon_delays.pickle', 'wb') as f:
        pickle.dump(delta, f)

    plt.boxplot(delta, labels=('BGP-TCP',))
    plt.grid()
    plt.ylabel('Propagation Time (ms)')
    plt.show()


if __name__ == '__main__':
    parser = ArgumentParser(description="Compute the propagation delay of BGP beacons")
    parser.add_argument('-d', '--dir', required=True, type=str,
                        help='Directory containing the Mrts of the BGP router receiver')
    parser.add_argument('-p', '--pfx', required=True, type=str,
                        help='Prefix we are interrested to compute the propagation delay')
    parser.add_argument('-c', '--collector', required=True, type=str,
                        help='The Collector BGP router (The router which sends BGP update '
                             'to our router)')
    parser.add_argument('-s', '--src-mrt', dest='src_mrt', required=True, type=str,
                        help='The mrt file that sends the BGP update')

    main(parser.parse_args())
