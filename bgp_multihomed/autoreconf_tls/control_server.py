#!/usr/bin/env python3
import argparse
import os
import selectors
import subprocess
from pathlib import Path
from tempfile import NamedTemporaryFile

import yaml

from bird_reconf.utils import SocketConfig, accept, io_loop, TYPE_CERT_LOCAL

from cryptography.x509 import Certificate

DEBUG = False


def is_root():
    return os.geteuid() == 0


def handle_script(config: dict) -> bool:
    status = True
    with NamedTemporaryFile(mode="w+", delete=False) as script_file:
        script_file.write(config['script'])

        # Make it executable
        os.fchmod(script_file.fileno(), 0o550)  # r-xr-x---
        os.fsync(script_file.fileno())
        script_file.close()

        cmd = [script_file.file.name] + config['script_args']
        try:
            subprocess.run(cmd, shell=False, check=True)
        except subprocess.CalledProcessError as e:
            status = False
            print(f'Failed to run {" ".join(cmd)}\n{e}')
        finally:
            os.unlink(script_file.file.name)

    return status


def handle_cmds(config: dict) -> bool:
    for cmd in config['cmds']:
        # apply all commands
        try:
            subprocess.run(cmd, shell=True, check=True)
        except subprocess.CalledProcessError as e:
            print(f"Failed to run '{cmd}': {e}")
            return False

    return True


def apply_config(config: dict) -> bool:
    dispatcher = {
        'script': handle_script,
        'cmds': handle_cmds
    }

    if config['type'] in dispatcher:
        return dispatcher[config['type']](config)
    else:
        raise RuntimeError(f"Unknown type {config['type']}")


def read_cert(cert: Certificate, config_cert: str, sock_conf: object, type_cfg: int) -> bool:
    try:
        conf_obj = yaml.safe_load(config_cert)
    except yaml.YAMLError as e:
        print(f"Failed while decoding yaml: {e}")
        return False

    print(f"Received {'local' if type_cfg == TYPE_CERT_LOCAL else 'remote'} config")

    if DEBUG:
        print(conf_obj)
        return True

    return apply_config(conf_obj)


def main(args):
    global DEBUG
    control_socket = Path(args.sock_path)
    if args.debug:
        DEBUG = True

    server_config = SocketConfig(
        on_sk_event=accept,
        pid=-1,
        context=None,
        control_socket_path=str(control_socket),
        sel=selectors.DefaultSelector(),
        on_cert_recv=read_cert
    )

    io_loop(server_config)
    raise RuntimeError('IO loop exited')


if __name__ == '__main__':
    if not is_root():
        print("Please run as root")
        exit(1)

    parser = argparse.ArgumentParser()

    parser.add_argument('-s', '--socket-path', dest='sock_path', required=False, type=str,
                        default='/tmp/bird_ctr.sk', help="Control socket of this server")
    parser.add_argument('-d', '--debug', dest='debug', required=False, action='store_true',
                        help='Enable debugging: just print config without applying it')

    main(parser.parse_args())
