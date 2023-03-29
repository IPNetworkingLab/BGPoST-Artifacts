import os
import time
from pathlib import Path
from random import Random
from types import MappingProxyType

DB_NAME = str(Path(__file__).parent.absolute().joinpath('peering'))
CERTS_PATH = str(Path(__file__).parent.absolute().joinpath('certs'))
BIRD_TEMPLATE = str(Path(__file__).parent.absolute().joinpath('templates/bgp_bird.jinja2'))
WG_TEMPLATE = 'templates/wg_config.yaml.jinja2'
CA_CERT = str(Path(__file__).parent.absolute().joinpath('certs/ca.cert.pem'))
CA_KEY = str(Path(__file__).parent.absolute().joinpath('certs/ca.key'))

MY_AS_CONFIG = MappingProxyType({
    'asn': 65000,
    'ip_endpoint': "192.168.2.1",
    'base_tunnel_pfx_llv6': "fe80::2315:0",
    'auto_tunnel_id': 2,  # we start auto IPv6-LL tunnel at fe80:2315::2/127
    'wg_listen_port': 43045,
    'wg_base_name': 'wg',
    'wg_base_id': 1,
    'sni': 'my_test.rtr',
})


def contains(field: str, data_form: dict) -> bool:
    return field in data_form and len(data_form[field]) > 0


def generate_filename():
    rng = Random()
    rng.seed(os.getpid() + int(time.time()))
    characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"
    return ''.join(rng.choices(characters, k=16))
