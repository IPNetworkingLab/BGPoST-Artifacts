import argparse

from pyroute2.netlink.nlsocket import Stats
from pyroute2 import IPRoute

from netutils.ip_utils import id_from_name

def collect_routes(ipr: IPRoute):
    """ Collect the FIB content """
    routes = {}
    for route in ipr.get_routes():

        if route['proto'] != 12: continue

        attrs = dict(route['attrs'])
        dst = attrs['RTA_DST']
        routes[dst] = []

        try:
            routes[dst].append(attrs['RTA_GATEWAY'])
        except KeyError:
            try:
                for path in attrs['RTA_MULTIPATH']:
                    subattrs = dict(path['attrs'])
                    routes[dst].append(subattrs['RTA_GATEWAY'])
            except KeyError:
                pass
    return routes

def collect_addrs(ipr: IPRoute):
    """ Collect addresses of the node """
    addrs = {}
    for addr in ipr.get_addr():
        idx = addr['index']
        ifa_addr = dict(addr['attrs'])['IFA_ADDRESS']
        try:
            addrs[idx].append(ifa_addr)
        except KeyError:
            addrs[idx] = [ifa_addr]
    return addrs

def collect():
    with IPRoute() as ipr:
        addrs = collect_addrs(ipr)
        routes = collect_routes(ipr)
    return {'routes': routes, 'addrs': addrs}

def dump(data: dict, prefix: str, name: str):
    import json
    import time
    import os
    
    node_id = str(id_from_name(name))
    path = os.path.join(prefix, node_id)
    if not os.path.exists(path): os.makedirs(path)
    timestamp = str(time.time_ns())
    filename = os.path.join(path, timestamp)

    with open(filename, 'w') as fd:
        json.dump(data, fd)

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument('node_name')

    args = parser.parse_args()
    node_name = args.node_name
    prefix = 'dumps'
    
    data = collect()
    dump(data, prefix, node_name)
