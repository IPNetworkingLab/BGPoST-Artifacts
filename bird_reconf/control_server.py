import argparse
import ipaddress
import selectors
import socket
from dataclasses import dataclass
from pathlib import Path
from typing import Union, Iterable

import yaml
from cryptography.hazmat._oid import ExtensionOID
from cryptography.x509 import Certificate

from jinja2 import Template

from bird_reconf.utils import decode_length, SocketConfig, io_loop, accept, TYPE_CERT_LOCAL

TAG_START = "###CONFIG_REMOVE_START###"
TAG_END = "###CONFIG_REMOVE_END###"


@dataclass
class Config(object):
    bird_sk: socket.socket
    current_cfg_file: str
    default_cfg: dict
    bgp_template: Template


def do_bird_reload(sk_bird: socket.socket, new_config_file: str):
    cli_response = sk_bird.recv(2048)

    if not ("ready" in cli_response.decode()):
        return False

    sk_bird.send(f'configure soft "{new_config_file}"\n'.encode())
    cli_response = sk_bird.recv(2048)

    status = True if "0003 Reconfigured" in cli_response.decode() else False

    return status


def find_end_block(sub, start_idx):
    found_start_brace = False
    brace_idx = start_idx - 1
    end_idx = -1
    stack = []

    # get start of block
    while not found_start_brace and start_idx < len(sub):
        brace_idx += 1
        if sub[brace_idx] == '{':
            found_start_brace = True
            stack.append(brace_idx)

    if not found_start_brace:
        raise ValueError("Malformed string !")

    end_idx = brace_idx
    while len(stack) > 0:
        end_idx += 1
        if sub[end_idx] == '}':
            stack.pop(0)
        elif sub[end_idx] == '{':
            stack.append(end_idx)

    return end_idx


def add_static_rte(old_config: str, new_routes: Iterable[str]):
    start_idx = old_config.find("protocol static {")
    end_idx = find_end_block(old_config, start_idx)

    proto_static_old = old_config[start_idx: end_idx]
    new_routes = '\n'.join([f"route {route} reject;" for route in new_routes if route not in proto_static_old])

    proto_static_new = f"{proto_static_old}\n" \
                       f"{new_routes}\n" "}"
    return proto_static_new, start_idx, end_idx


def rebuild_static_proto(old_cfg: str, new_routes: Iterable[str]):
    new_static, old_start, old_end = add_static_rte(old_cfg, new_routes)
    return old_cfg[:old_start] + new_static + old_cfg[old_end + 1:]


def remove_config(cfg: str):
    current_cfg = cfg

    while (start_idx := current_cfg.find(TAG_START)) != -1:
        end_idx = current_cfg.find(TAG_END)
        end_idx += len(TAG_END)
        current_cfg = current_cfg[:start_idx] + current_cfg[end_idx:]

    return current_cfg


def increment_file_version(file_name: str):
    f_split = file_name.split('.')

    try:
        current_version = int(f_split[-1])
        f_split[-1] = str(current_version + 1)
    except ValueError:
        f_split.append("2")

    return '.'.join(f_split)


def reload_config(default_cfg: dict, yaml_cfg: dict,
                  current_bird_cfg: str, bgp_proto_template: Template,
                  bird_sk: socket.socket):
    with open(current_bird_cfg, 'r') as f:
        old_conf = f.read()

    # 1. render bgp config from template
    bgp_proto = bgp_proto_template.render({**yaml_cfg, **default_cfg})
    # Put this new conf into tags in case of a next reconfig
    bgp_proto = f"{TAG_START}\n{bgp_proto}\n{TAG_END}"

    # 2. remove unnecessary config for a config reload
    pre_new_cfg = remove_config(old_conf)

    # 3. regenerate proto static config from old config
    pre_new_cfg = rebuild_static_proto(pre_new_cfg, yaml_cfg['export_static_rte'])

    # 4. add new BGP proto to the config
    new_cfg = pre_new_cfg + '\n' + bgp_proto

    # 5. write new bird config
    old_cfg_path = Path(current_bird_cfg)
    new_cfg_path = old_cfg_path.parent.joinpath(increment_file_version(old_cfg_path.name))
    with open(new_cfg_path, 'w') as f_cfg:
        f_cfg.write(new_cfg)

    # 6. Perform reload with CLI socket
    if not do_bird_reload(bird_sk, str(new_cfg_path)):
        # Oh, no! Reconfig has failed
        return None

    return str(new_cfg_path)


def decode_ip_from_subject_altname(sequence_string: bytes) -> Union[ipaddress.IPv4Address | ipaddress.IPv6Address]:
    assert sequence_string[0] == 0x30, f"Value is not a sequence"
    length, offset = decode_length(sequence_string[1:])
    curr_read = 1 + offset

    while curr_read < length:
        type_tag = sequence_string[curr_read]
        type_length, type_offset = decode_length(sequence_string[curr_read + 1:])
        curr_read += 1 + type_offset
        if type_tag & 0x1f == 7:  # 7 is choice for IPaddress
            ip_addr_int = int.from_bytes(sequence_string[curr_read: curr_read + type_length], byteorder='big')
            return ipaddress.ip_address(ip_addr_int)
        curr_read += type_length

    raise ValueError


def read_cert_and_reload_config(cert: Certificate, local_config: str, config: Config, type_cfg: int) -> bool:
    if type_cfg == TYPE_CERT_LOCAL:
        print("Local config not supported yet")
        return False

    sub_alt_name = cert.extensions.get_extension_for_oid(ExtensionOID.SUBJECT_ALTERNATIVE_NAME)
    # 1. Get IP of the remote router
    ip_addr = decode_ip_from_subject_altname(sub_alt_name.value.public_bytes())
    # 2. Get custom field that holds the configuration to set in my router

    # 3. decode config
    try:
        conf_obj = yaml.safe_load(local_config)
    except ValueError:
        print("Failed to decode yaml")
        return False
    except UnicodeDecodeError:
        print("Non unicode character detected in config !")
        return False
    except yaml.YAMLError as e:
        print(f"YAML decode error! {e}")
        return False

    if ipaddress.ip_address(conf_obj['remote_ip']) != ip_addr:
        print(f"Subject Alt NAME IP ({ip_addr}) "
              f"does not match with the config ({conf_obj['remote_ip']}) :(")
        return False

    # 4. reload bird daemon with new config
    new_config_file = reload_config(default_cfg=config.default_cfg,
                                    yaml_cfg=conf_obj,
                                    current_bird_cfg=config.current_cfg_file,
                                    bgp_proto_template=config.bgp_template,
                                    bird_sk=config.bird_sk)
    if new_config_file is not None:
        # update master config with new config file
        config.current_cfg_file = new_config_file
        return False
    return True


def open_cli_sock(bird_ctrl_path: str):
    cli_sk = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    cli_sk.connect(bird_ctrl_path)
    return cli_sk


def main(args):
    control_socket = Path(args.sock_path)
    bird_cli = open_cli_sock(args.bird_sk)

    with open(args.template, 'r') as tmpl:
        template = Template(tmpl.read())

    with open(args.default_bird_cfg, 'r') as f:
        default_bird_cfg = yaml.safe_load(f)

    master_config = Config(bird_sk=bird_cli,
                           bgp_template=template,
                           current_cfg_file=args.config,
                           default_cfg=default_bird_cfg)

    server_config = SocketConfig(
        on_sk_event=accept,
        pid=-1,
        context=master_config,
        control_socket_path=str(control_socket),
        sel=selectors.DefaultSelector(),
        on_cert_recv=read_cert_and_reload_config
    )

    io_loop(server_config)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-s', '--socket-path', dest='sock_path', required=False, type=str,
                        default='/tmp/bird_ctr.usock', help="Control socket of this server")
    parser.add_argument('-t', '--template', dest='template', required=True, type=str,
                        help='Bird template used to reconfig the BIRD daemon')
    parser.add_argument('-c', '--config', dest='config', required=True, type=str,
                        help='The BIRD config the daemon is currently using at the'
                             'time this script is launched')
    parser.add_argument('-b', '--bird-sock', dest="bird_sk", required=True, type=str,
                        help="Bird CLI socket path")
    parser.add_argument('-d', '--default-bird-cfg', dest='default_bird_cfg',
                        required=True, type=str,
                        help='Default variable config to generate new configuration')

    main(parser.parse_args())
