#!/usr/bin/env python3
import math
import os.path
import pickle
import tarfile
from argparse import ArgumentParser
from pathlib import Path
from tarfile import TarFile
from tempfile import TemporaryDirectory
from time import sleep
from typing import TextIO

import ijson
import matplotlib.pyplot as plt

from blackholing.randy_exp.tls.tls_update_propagation import parse_mrt, Interval
from bgp_multihomed.parse_bw_pcapng import process_data


def handler_builder(ip_dst: str):
    def tshark_record_process(f: TextIO):
        start_tls_time = []
        for record in ijson.items(f, 'item'):
            layers = record['_source']['layers']

            protocols = layers['frame.protocols'][0]
            time = float(layers['frame.time_epoch'][0])

            if 'tls' not in protocols:
                continue
            if 'tls.handshake.type' not in layers:
                continue

            trace_ip_dst = layers['ip.dst'][0]
            tls_handshake_type = int(layers['tls.handshake.type'][0])

            if trace_ip_dst != ip_dst:
                continue

            if tls_handshake_type != 1:
                continue

            start_tls_time.append(time)

        return start_tls_time

    return tshark_record_process


def handle_tls_trace(ip_dst, pcap):
    fields = ['frame.protocols', 'frame.time_epoch',
              'ip.src', 'ip.dst',
              'tls.handshake.type']
    tshark_processor = handler_builder(ip_dst)

    tls_start_time = process_data(pcap, tshark_processor, fields)
    assert len(tls_start_time) == 1, 'TLS session established more than once !'
    return tls_start_time[0]


def parse_pcap_from_tar(tar_file: TarFile, ip_dst):
    with TemporaryDirectory() as temp_dir:
        member = tar_file.getmember("dev/shm/tls_blackhole/trace.pcap")
        member.name = os.path.basename(member.name)
        tar_file.extract(member, path=temp_dir)
        tls_start_time = handle_tls_trace(ip_dst, f'{temp_dir}/trace.pcap')

    return tls_start_time


def parse_tls_start_traces(exp_dir: str, ip_dst: str):
    start_tls_times = []
    experiment_dir = Path(exp_dir)

    if not experiment_dir.is_dir():
        raise ValueError(f"Not a dir {exp_dir}")

    archives = [x for x in experiment_dir.glob('exp_run_*.tar.xz') if x.is_file()]

    for archive in archives:
        with tarfile.open(str(archive)) as t:
            start_tls_times.append(parse_pcap_from_tar(t, ip_dst))

    start_tls_times.sort()
    return [int(x * 10 ** 6) for x in start_tls_times]


def main(args):
    start_tls = parse_tls_start_traces(args.dir, args.ip_dst)
    interval = Interval(-math.inf, math.inf)
    recv_update = parse_mrt(args.mrt, args.pfx, False, interval)

    assert len(start_tls) == len(recv_update), (f'Mismatch BGP Update numbers. '
                                                f'Sent: {len(start_tls)}, Recv: {len(recv_update)}')

    delta = [(recv - sent) / 10 ** 3 for sent, recv in zip(start_tls, recv_update)]

    with open('tls_dyn_update.pickle', 'wb') as f:
        pickle.dump(delta, f)

    plt.boxplot(delta, labels=('Handshake + update',))
    plt.grid()
    plt.ylabel('Time (ms)')
    plt.show()


#  PYTHONPATH=../../.. ./tls_creation_message_propagation.py -d /home/thomas/Bureau/bgptls/blackhole/exp_runs/ --dest-ip 198.180.150.60 -p 203.0.113.0/24 --mrt /home/thomas/Bureau/bgptls/blackhole/tls_blackhole.bbte.tls_exp.mrt

if __name__ == '__main__':
    parser = ArgumentParser(description='Parse Time to open TLS and propagate BGP Update')
    parser.add_argument('-d', '--dir', required=True, type=str,
                        help='Directory containing TLS src exp runs (exp_run_*.tar.xz)')
    parser.add_argument('--dest-ip', dest='ip_dst', required=True, type=str,
                        help="IP address on which BGP-TLS is established")
    parser.add_argument('--mrt', required=True, type=str,
                        help="MRT file containing the bgp update on the target BGP router "
                             "(the one that receives the blackhole)")
    parser.add_argument('-p', '--pfx', required=True, type=str,
                        help='Prefix contained in BGP updates of the MRT file')

    main(parser.parse_args())
