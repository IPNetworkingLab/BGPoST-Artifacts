#!/usr/bin/env python3
import os
import select
import sys
from argparse import ArgumentParser
from threading import Thread
from time import sleep
from typing import Union
from ipaddress import ip_network, IPv4Network

STOP = False


def stop():
    global STOP
    STOP = True


def zombie():
    return os.getppid() == 1


def stdin_reader():
    try:
        while not zombie() and not STOP:
            r, _, _ = select.select([sys.stdin.fileno()], [], [], 1)

            if len(r) == 1:
                line = sys.stdin.readline()
                line = line.strip()
                if not line or 'shutdown' in line:
                    stop()
                    break
    except IOError:
        stop()


def gen_announcement(pfx: str, next_hop: str, asn: int, origin: str = 'INCOMPLETE') -> Union[None | str]:
    valid_origins = ['IGP', 'EGP', 'INCOMPLETE']

    origin = origin.upper()
    if origin not in valid_origins:
        return None

    return f'announce route {pfx} next-hop {next_hop} origin {origin} as-path [ {asn} ]'


def announce(announcement: str):
    sys.stdout.write(announcement + '\n')
    sys.stdout.flush()


def start_reader():
    t = Thread(target=stdin_reader)
    t.start()
    return t


def controlled_announcement(pfxs: str, ipv4_nh: str, ipv6_nh: str, asn: int, delay_ms: int, max_announce: int = 0):
    nb_announce = 0

    delay_s = delay_ms / 1000
    with open(pfxs) as f:
        for line in f.readlines():
            if 0 < max_announce <= nb_announce:
                return
            if STOP:
                return
            line = line.strip()

            pfx = ip_network(line)
            nh = ipv4_nh if isinstance(pfx, IPv4Network) else ipv6_nh

            # I don't care of origin, make it incomplete by default
            bgp_route = gen_announcement(str(pfx), nh, asn)
            if bgp_route is not None:
                announce(bgp_route)
                nb_announce += 1
                sleep(delay_s)


def main(args):
    try:
        t = start_reader()
        controlled_announcement(args.prefixes, args.ipv4_nh,
                                args.ipv6_nh, args.asn, args.delay,
                                args.max_announce)
    except:
        stop()
    finally:
        # block during ExaBGP execution
        # if not stopped otherwise
        t.join()


if __name__ == '__main__':
    parser = ArgumentParser(description='Announce routes')
    parser.add_argument('--ipv6-nh', dest='ipv6_nh', required=True, type=str,
                        help='IPv6 Nexthop of the routes sent to the ExaBGP neighbors')
    parser.add_argument('--ipv4-nh', dest='ipv4_nh', required=True, type=str,
                        help='IPv4 Next-Hop to announce to the ExaBGP neighbors')
    parser.add_argument('-a', '--asn', required=True, type=str,
                        help='AS Number of the this ExaBGP instance')
    parser.add_argument('-p', '--prefixes', type=str, required=True,
                        help='File path containing the list of prefixes to send to ExaBGP neighbors')
    parser.add_argument('-d', '--delay', required=False, type=int, default=50,
                        help='Delay to wait between two route advertisements (default: 50ms)')
    parser.add_argument('-m', '--max-announce', dest='max_announce', required=False,
                        type=int, default=0, help='Number of routes to generate (default: announce all '
                                                  'routes contained in the file given in the -p argument)')

    main(parser.parse_args())
