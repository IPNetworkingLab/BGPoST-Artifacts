from dataclasses import dataclass
from copy import deepcopy as dp
import argparse
import json
import os

from netutils.ip_utils import lo_from_id, id_from_name


@dataclass
class Snapshot:
    timestamp: int
    fibs: dict
    addrs: dict


class Parser:

    fibs = {}
    nodes = []
    timestamps = []

    def __init__(self, prefix: str):
        self.collect(prefix)

    def collect(self, prefix: str):
        if not os.path.exists(prefix): 
            print('Prefix <%s> does not exist.' % prefix)
            return None
        for node in os.listdir(prefix):
            path = os.path.join(prefix, node)
            node = int(node)
            self.nodes.append(node)
            if not os.path.isdir(path):
                print('Entry <%s> is not a directory.' % node)
                continue
            for timestamp in os.listdir(path):
                with open(os.path.join(path, timestamp), 'r') as fd:
                    dump = json.load(fd)
                timestamp = int(timestamp)
                try:
                    self.fibs[timestamp][node] = dump
                except KeyError:
                    self.fibs[timestamp] = {node: dump}

        self.timestamps = sorted(self.fibs)

    def get_snapshot(self, cutoff: int, previous: Snapshot = None) -> Snapshot:

        if cutoff not in self.fibs:
            print('The provided cutoff timestamp was not found in the considered ones.')
            return None

        fibs = previous.fibs if previous is not None else {}
        addrs = previous.addrs if previous is not None else {}
        start = self.timestamps.index(previous.timestamp)+1 if previous is not None else 0
        end = self.timestamps.index(cutoff)+1

        if end < start:
            print('The first timestamp to consider is bigger than the last one')
            return None

        for timestamp in self.timestamps[start:end]:
            for node, node_data in self.fibs[timestamp].items():
                fibs[node] = node_data['routes']
                for _, node_addrs in node_data['addrs'].items():
                    for addr in node_addrs:
                        addrs[addr] = node

        return Snapshot(cutoff, fibs, addrs)

    def snapshots(self) -> list[Snapshot]:
        snapshots = []
        snap = None
        for timestamp in self.timestamps:
            snap = self.get_snapshot(timestamp, snap)
            snapshots.append(snap)
        return snapshots 

    def get_routes(self, snapshot: Snapshot = None) -> dict:

        def explore(dst_ip: str, current_node: int, route: list, collect: list):
            
            if lo_from_id(current_node) == dst_ip: 
                collect.append(route)
                return

            try:
                nexthops = snapshot.fibs[current_node][dst_ip]
                for nexthop in nexthops:
                    try:
                        nexthop_id = snapshot.addrs[nexthop]
                        explore(dst_ip, nexthop_id, list(route + [nexthop_id]), collect)
                    except KeyError:
                        print('No nexthop found')
            except KeyError:
                print('No route toward <%s> at node <%i>' % (tail_ip, current_node))

        if snapshot is None:
            snapshot = self.get_snapshot(self.timestamps[-1])

        routes = {}
        for head in self.nodes:
            for tail in self.nodes:
                if head == tail: continue
                
                tail_ip = lo_from_id(tail)

                collect = []
                explore(tail_ip, head, [head], collect)
                try:
                    routes[head][tail] = collect
                except KeyError:
                    routes[head] = {tail: collect}
        return routes


def cli(args: dict):

    fib_parser = Parser(args.prefix)

    """
    snapshots = fib_parser.snapshots()
    for snap in snapshots:
        print(snap)
    """

    snap = fib_parser.get_snapshot(fib_parser.timestamps[-1])
    print('\n', snap)
    routes = fib_parser.get_routes(snap)
    for head, data in routes.items():
        for tail, routes in data.items():
            print(head, tail, routes)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    parser.add_argument('prefix')

    args = parser.parse_args()
    cli(args)
