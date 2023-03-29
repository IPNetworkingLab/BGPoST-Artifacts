#! /bin/env python3

import concurrent.futures
import subprocess as sp
import socket
import os

from defusedxml.ElementTree import parse

from myutils import ip

ROOT = os.environ.get('ROOT', '/root')

def setup_links(links_path: str, dry: bool = False):

    """ Whoami? """
    whoami_result = sp.run("geni-get client_id".split(), capture_output=True)
    if whoami_result.returncode == 1:
        print('Failed to get client_id')
        exit(1)
    whoami = whoami_result.stdout.decode('utf-8').splitlines()[0]

    """ Fetch manifest file """
    manifest_path = '/tmp/manifest.xml'
    manifest_result = sp.run("geni-get manifest > {}".format(manifest_path), capture_output=True, shell=True)
    if manifest_result.returncode == 1:
        print('Failed to fetch the manifest')
        exit(1)

    parsed_manifest = parse(manifest_path)

    """ Create mapping: for each phynode we map a vlanid with a node name """
    mapping = {}

    def add_to_map(phynode: str, vlantag: int, node: str):
        phynode = phynode.attrib['client_id'].split(':')[0] 
        try:
            mapping[phynode][node]['tags'].append([vlantag])
        except KeyError:
            try:
                mapping[phynode][node] = {'tags': [[vlantag]], 'count': 0}
            except KeyError:
                mapping[phynode] = {node: {'tags': [[vlantag]], 'count': 0}}
        
    myself = socket.gethostname().split('.')[0]
    for child in parsed_manifest.getroot():
        if 'link' in child.tag:
            head, tail, _ = child.attrib['client_id'].split('_')
            vlantag = child.attrib['vlantag']

            interfaces = [subchild for subchild in child if 'interface_ref' in subchild.tag]
            if len(interfaces) != 2:
                print('More than two interfaces for the current link')
                continue
            
            add_to_map(interfaces[0], vlantag, head)
            add_to_map(interfaces[1], vlantag, tail)

        elif 'node' in child.tag and child.attrib['client_id'] == myself:
            for element in child:
                if 'vnode' in element.tag:
                    vnode = element.attrib['name']
                    with open(f'{os.environ.get("ROOT")}/vnode', 'w') as fd:
                        fd.write(vnode)

    print(mapping)


    # TODO test if path is file
    if not os.path.exists(links_path): 
        if len(mapping) == 0: return
        else: exit(1)

    with open(links_path, 'r') as fd:
        links_data = fd.read()
    links_data = links_data.splitlines()
    for line in links_data:
        node_id, iface_id = line.split('_')
        node = 'node%s' % node_id
        new_name = 'veth%s%s' % (node_id, iface_id)
        print(whoami, node)
        count = mapping[whoami][node]['count']
        mapping[whoami][node]['tags'][count].append(new_name)
        mapping[whoami][node]['count'] += 1

    """ Rename and move phynode interfaces into nodes """
    for node, node_data in mapping[whoami].items():
        for vlantag, veth in node_data['tags']:
            iface = 'vlan%s' % vlantag
            ip('l set dev %s down' % iface, dry)
            ip('l set dev %s name %s' % (iface, veth), dry)
            ip('l set dev %s netns %s' % (veth, node), dry)
            ip('-n %s l set dev %s up' % (node, veth), dry)
        
def validate_topo(checks: list):

    """ Launch neighbor discovery tool on each node in their own thread """
    with concurrent.futures.ThreadPoolExecutor() as executor:
        futures = {}
        for expected in checks:
            node = os.path.splitext(os.path.split(expected)[-1])[0]
            futures[node] = executor.submit(ip, f'netns exec {node} bash -c "{ROOT}/discovery {node} > {ROOT}/discovery_{node}.log"')

    """ Join the threads and check for each node if the discovered neighbors correspond to the
        expected ones.
    """
    got = {}
    for node, future in futures.items():
        result = future.result()
        if result.returncode == 1:
            exit(1)

        """ Test if discovery tool output exists """
        out_file = '%s.out' % node 
        if not os.path.exists(out_file): 
            print('Output file <%s> not found.' % out_file)
            continue

        """ Parse and collect the results of the neighbor discovery """
        with open(out_file, 'r') as fd:
            data = fd.read()
        peers = {}
        for line in data.splitlines():
            iface, neighbor = line.split(' ')
            try:
                peers[neighbor].append(iface)
            except KeyError:
                peers[neighbor] = [iface]
        got[node] = peers

    
    for expected in checks:
        """ Test if expected result file exists """
        if not os.path.exists(expected):
            print('Output file <%s> not found.' % out_file)
            continue

        """ Parse the expected peers and compared them with the discovered ones """
        with open(expected, 'r') as fd:
            data = fd.read()
        node = os.path.splitext(os.path.split(expected)[-1])[0]

        for line in data.splitlines():
            peer, expected_count = line.split('_')
            try:
                real_count = len(got[node][peer])
                if real_count != int(expected_count):
                    print('We expected <%s> links between nodes <%s> and <%s> but we discovered <%s>' %
                          (expected_count, node, peer, real_count))
                    exit(1)
                print('We found <%s> links between nodes <%s> and <%s> as expected.' % 
                      (real_count, node, peer))
            except KeyError:
                print('Peer <%s> not discovered for node <%s>' % (peer, node))
                exit(1)

    print('Topology checks passed successfully.')


if __name__ == "__main__":

    import argparse
    import time

    parser = argparse.ArgumentParser()
    parser.add_argument('links', help='The path towards links file.')
    parser.add_argument('--dry', action='store_true', default=False, help='Does not execute the commands.')
    parser.add_argument('--check', nargs='*', help='The list of nodes to check.')

    args = parser.parse_args()

    setup_links(args.links, args.dry)
    time.sleep(2)

    if args.check: validate_topo(args.check)
