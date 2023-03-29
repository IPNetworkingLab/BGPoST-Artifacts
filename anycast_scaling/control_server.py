#! /usr/bin/env python3
import argparse
import re
import selectors
import socket
from dataclasses import dataclass
from pathlib import Path
from typing import Union

import yaml
from cryptography.x509 import Certificate

from bird_reconf.utils import SocketConfig, accept, io_loop, TYPE_CERT_LOCAL


@dataclass
class CfgCtx(object):
    bird_sk: socket
    bird_conf: str
    bird_conf_dir: Path
    bird_conf_name: str


def open_cli_sock(bird_ctrl_path: str):
    cli_sk = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    cli_sk.connect(bird_ctrl_path)

    # check if cli is ready
    cli_response = cli_sk.recv(2048)
    if "ready" not in cli_response.decode():
        print("BIRD CLI not ready")
        return None

    return cli_sk


def read_file(file: str) -> str:
    with open(file, 'r') as f:
        content = f.read()
    return content


def add_filter(cfg: str, bird_filter: str) -> Union[None | str]:
    find_str = '# @@@ FILTER CERT\n'

    start_idx = cfg.find(find_str)

    if start_idx == -1:
        return None

    end_idx = start_idx + len(find_str)

    return f'{cfg[:end_idx]}\n{bird_filter}\n{cfg[end_idx:]}'


def replace_table_config(cfg: str, peer_name: str, filter_name: str) -> Union[None | str]:
    find_str_start = f'# @@@ BEGIN ANYCAST {peer_name} IPV4 TABLE @@@\n'
    find_str_end = f'# @@@ END ANYCAST {peer_name} IPV4 TABLE @@@\n'
    new_table_cfg = "  ipv4 {\n" \
                    "    import table on;\n" \
                    f"    import filter {filter_name};\n" \
                    "    export all;\n" \
                    "  };\n"

    start_idx = cfg.find(find_str_start)
    if start_idx == -1:
        return None
    start_idx += len(find_str_start)
    end_idx = cfg.find(find_str_end)

    return f'{cfg[:start_idx]}\n{new_table_cfg}\n{cfg[end_idx:]}'


def new_name(current_name: str):
    pfx_regex = r"(\d+)-(.+)"
    m = re.match(pfx_regex, current_name)

    if m is None:
        return f"2-{current_name}"
    else:
        current_iter = int(m.group(1))
        name = m.group(2)
        return f"{current_iter + 1}-{name}"


def reload_config(sk_bird: socket.socket, config_path: str):
    sk_bird.send(f'configure "{config_path}"\n'.encode())
    cli_response = sk_bird.recv(2048)

    return True if "003 Reconfigured" in cli_response.decode() else False


def apply_config(config: dict, context: CfgCtx):
    new_cfg = context.bird_conf

    # 1. add filter
    new_cfg = add_filter(new_cfg, config['filter'])
    if new_cfg is None:
        return False

    # 2. modify table config
    new_cfg = replace_table_config(new_cfg, config['peer'], config['filter_name'])
    if new_cfg is None:
        return False

    # 3. Write new config on file
    new_file_name = new_name(context.bird_conf_name)
    full_path = context.bird_conf_dir.joinpath(new_file_name)
    with open(str(full_path), 'w') as f:
        f.write(new_cfg)

    # 4. Reconfigure BIRD with the new config file
    if not reload_config(context.bird_sk, str(full_path)):
        print("Failed to reconfigure BIRD via CLI")
        return False

    # TODO how to handle session restart ?

    return True


def read_cert(cert: Certificate, config_cert: str, context: CfgCtx, type_cfg: int) -> bool:
    try:
        conf_obj = yaml.safe_load(config_cert)
    except yaml.YAMLError as e:
        print(f"Failed while decoding yaml: {e}")
        return False

    if type_cfg == TYPE_CERT_LOCAL:
        print("Received local config, ignoring")
        return True

    return apply_config(conf_obj, context)


def main(args):
    control_socket = Path(args.sock_path)
    conf_path = Path(args.config)
    bird_sk_cli = open_cli_sock(args.bird)
    if bird_sk_cli is None:
        return

    context = CfgCtx(
        bird_conf=read_file(args.config),
        bird_conf_dir=conf_path.parent,
        bird_conf_name=conf_path.name,
        bird_sk=bird_sk_cli
    )

    server_config = SocketConfig(
        on_sk_event=accept,
        pid=-1,
        context=context,
        control_socket_path=str(control_socket),
        sel=selectors.DefaultSelector(),
        on_cert_recv=read_cert
    )

    io_loop(server_config)
    raise RuntimeError('IO loop exited')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    parser.add_argument('-s', '--socket-path', dest='sock_path', required=True,
                        type=str, help="Control socket of this server")
    parser.add_argument('-b', '--bird', required=True, type=str,
                        help="BIRD control socket")
    parser.add_argument('-c', '--config', required=True, type=str,
                        help='Path to the BIRD config file')

    main(parser.parse_args())
