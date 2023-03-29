#! /usr/bin/env python3
from threading import Event, Thread, enumerate as thread_enum, current_thread
from select import poll
import argparse
import signal
import time

import yaml
from pyroute2 import IPRoute, NetNS


def handler(a, b):
    stop.set()


def collect(stop, results, ns: str = None):
    print(f'Collection started for {ns}\n')
    ipr = IPRoute() if ns is None else NetNS(ns)
    ipr.bind()
    p = poll()
    p.register(ipr)
    while True:
        content = p.poll(1)
        if len(content) == 0:
            if stop.is_set():
                print(f'Collection stopped for {ns}')
                break
            else:
                continue
        ts = time.time_ns()
        results.append((ts, [m for m in ipr.get()]))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-o', '--output', type=str, required=True,
                        help='Output file')
    parser.add_argument('netns', type=str, nargs='+')
    args = parser.parse_args()

    signal.signal(signal.SIGINT, handler)
    stop = Event()
    results = []

    for ns in args.netns:
        res = []
        results.append(res)
        Thread(target=collect, name=ns, args=[stop, res, ns]).start()

    for t in thread_enum():
        if t != current_thread():
            t.join()

    results = {ts: msgs for entry in results for (ts, msgs) in entry}
    print(f'Collected {len(results)} entries')
    with open(args.output, 'w') as fd:
        yaml.dump(results, fd)
