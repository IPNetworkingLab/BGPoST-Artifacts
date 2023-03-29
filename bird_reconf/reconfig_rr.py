#!/usr/bin/env python3
import argparse
import asyncio
import ipaddress
import logging
import os
import socket
import sys
import time
from enum import Enum
from typing import Union

import pythonping.executor
from jinja2 import Template
from pythonping import ping
from ipaddress import IPv4Address, IPv6Address


class ProtoState(Enum):
    UNK = 0
    UP = 1
    DOWN = 2


async def do_ping(ip: Union[IPv4Address, IPv6Address], timeout: float = 0.2, count: int = 4):
    r = ping(str(ip), timeout=timeout, count=count)
    return (r.rtt_avg_ms, ip) if r.success(pythonping.executor.SuccessOn.All) else (None, ip)


def select_best_server(ips: list[Union[IPv4Address, IPv6Address]]):
    async def select_best_server__(addresses: list[Union[IPv4Address, IPv6Address]]):
        pings = await asyncio.gather(*[do_ping(ip) for ip in addresses])
        # FIXME there could be no reachable servers. Min will throw an exception
        return min(((rtt, ip) for rtt, ip in pings if rtt is not None), key=lambda t: t[0])[1]

    return asyncio.run(select_best_server__(ips))


def modify_cfg(template: Template, new_ip: Union[IPv4Address | IPv6Address],
               out_file_path: str):
    with open(out_file_path, 'w') as out_f:
        out_f.write(template.render(rr_ip=str(new_ip)))


def reload_config(sk_bird: socket.socket, new_config_file: str):
    cli_response = sk_bird.recv(2048)

    if not "ready" in cli_response.decode():
        logger.warning("Bird CLI not ready :(")
        return False

    sk_bird.send(f'configure soft "{new_config_file}"\n'.encode())
    cli_response = sk_bird.recv(2048)

    status = True if "0003 Reconfigured" in cli_response.decode() else False

    sk_bird.close()
    return status


def get_rr_server_state(sk_bird: socket.socket, bgp_name: str):
    """
    Get the current status of the BGP session identified by @p bgp_name
    in the BIRD daemon.
    @param sk_bird: the socket connected to the CLI of the BIRD daemon
    @param bgp_name:
    @return:  UP if the session is established
            DOWN if the session is no more established
             UNK if it fails to retrieve the state of the BGP session
    """
    sk_bird.send(f"show protocols {bgp_name}\n".encode())
    cli_response = sk_bird.recv(1024)

    cli_response = cli_response.decode()
    # todo check this. Not sure
    if "up" in cli_response and "Established" in cli_response:
        return ProtoState.UP
    elif "start" in cli_response and "Established" not in cli_response:
        return ProtoState.DOWN
    else:
        logger.error(f"Protocol state in unknown state. CLI response dump:{cli_response}\n")
        return ProtoState.UNK


def reconfig_bird(addresses: list[Union[IPv4Address, IPv6Address]],
                  template: Template, dest_cfg_file: str,
                  sk_bird: socket.socket) -> Union[IPv4Address | IPv6Address | None]:
    """
    Reconfigure the BGP connection with a new route reflector address
    contained in @p addresses. It tries to choose the server with the
    lowest ping RTT.

    @param addresses: The list of address of route reflectors available
    @param template: the BIRD configuration template to modify with
                     the selected route reflector
    @param dest_cfg_file: the destination path of the new BIRD configuration file with the
                          new rr server chosen by this function.
    @param sk_bird: the connected socket with the BIRD daemon
    @return: return the new route reflector address chosen. Non if it fails to reconfigure the
             BIRD daemon.
    """
    ret_val = None
    best = select_best_server(addresses)

    modify_cfg(template, best, dest_cfg_file)

    status = reload_config(sk_bird, dest_cfg_file)
    if not status:
        logger.warning(f"Unable to reconfigure BIRD with new best RR server: {best}")
    else:
        ret_val = best
        logger.info(f"BIRD reconfigured with new best RR server: {best}")

    return ret_val


def poll_until_server_fails(sk_bird: socket.socket, bgp_name: str, poll_time_s: float = 0.25):
    """
    Continuously poll the BIRD daemon until the BGP session identified by @p bgp_name is DOWN.
    @param sk_bird: the connected socket with the BIRD daemon
    @param bgp_name: the name of the BGP session to monitor
    @param poll_time_s:
    @return: True if the BGP session is down
             False if any errors during the polling phase.
    """
    while True:
        time.sleep(poll_time_s)
        state = get_rr_server_state(sk_bird, bgp_name)
        if state == ProtoState.DOWN:
            logger.info(f"Connection lost with {bgp_name}")
            return True
        elif state == ProtoState.UNK:
            logger.error("Internal Error, cannot get protocol state")
            return False


def loopyloop(sk_bird: socket.socket, rr_addrs: list[Union[IPv4Address | IPv6Address]],
              dest_cfg_file: str, template: Template, bgp_name: str):
    current_rr_addr = None
    while True:
        if poll_until_server_fails(sk_bird, bgp_name):
            poll_addrs = [address for address in rr_addrs if address != current_rr_addr]
            new_best_rr = reconfig_bird(poll_addrs, template, dest_cfg_file, sk_bird)
            if new_best_rr is None:
                logger.error('Unable to reconfigure bird with new RR address. Exiting...')
                return
            current_rr_addr = new_best_rr
        else:
            logger.error('BIRD proto state in unknown state. Exiting...')
            return


def main(args):
    # load bird template
    with open(args.template, 'r') as tmpl:
        template = Template(tmpl.read())

    # open connection with CLI socket
    sk_bird = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sk_bird.connect(args.bird_socket)

    # check if IP addresses are in the correct format by
    # passing them to the ipaddress api
    rr_addrs = [ipaddress.ip_address(address) for address in args.route_reflectors]

    # monitor BIRD process and reconfig session
    # with a new RR if it fails
    loopyloop(sk_bird=sk_bird, rr_addrs=rr_addrs,
              dest_cfg_file=args.cfg_file, template=template,
              bgp_name=args.name)

    sk_bird.close()


def is_root():
    return os.geteuid() == 0


def setup_custom_logger(name: str):
    formatter = logging.Formatter(fmt='%(asctime)s %(levelname)-8s %(message)s',
                                  datefmt='%Y-%m-%d %H:%M:%S')
    # handler = logging.FileHandler('log.txt', mode='w')
    # handler.setFormatter(formatter)
    screen_handler = logging.StreamHandler(stream=sys.stdout)
    screen_handler.setFormatter(formatter)
    logger__ = logging.getLogger(name)
    logger__.setLevel(logging.DEBUG)
    # logger.addHandler(handler)
    logger__.addHandler(screen_handler)
    return logger__


if __name__ == '__main__':
    if not is_root():
        print("This script must be run as root")
        exit(1)

    logger = setup_custom_logger("reconfig")

    parser = argparse.ArgumentParser()
    parser.add_argument('-r', '--route-reflectors', dest="route_reflectors", nargs='+',
                        required=True, help='Lists of IP addresses of Route Reflectors to try to connect')
    parser.add_argument('-t', '--template', dest='template', required=True,
                        help='The jinja template of the route reflector client to modify')
    parser.add_argument('-c', '--cfg-file', dest='cfg_file', required=True,
                        help='Configuration path with the new route reflector to be configured')
    parser.add_argument('-s', '--socket', dest='bird_socket', required=True,
                        help='The socket corresponding to the route reflector client to '
                             'use when reconfiguring the client configuration.')
    parser.add_argument('-n', '--name', dest='name', required=True,
                        help='The name used by BIRD to identify the route reflector server')

    args_ = parser.parse_args()
    main(args_)
