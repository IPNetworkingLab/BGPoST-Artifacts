import random
import subprocess
import sys
import zipfile
from pathlib import Path
from tempfile import NamedTemporaryFile, SpooledTemporaryFile
from zipfile import ZipFile

from SimpleDB import MiniDB, db_get
from utils import DB_NAME, contains, WG_TEMPLATE, CERTS_PATH, BIRD_TEMPLATE, \
    MY_AS_CONFIG, generate_filename, CA_KEY, CA_CERT

from ipaddress import ip_address
from flask import Flask
from jinja2 import Template

from wireguard_tools import WireguardKey

from x509_csr import read_cert, read_privkey, gen_sign_cert


def fill_missing_fields(form_config: dict):
    db = db_get().db

    v6_endpoint_id = db['auto_tunnel_v6']
    my_endpoint = db['llv6_base_pfx'] + v6_endpoint_id

    if not contains('dn42_ip6', form_config):
        their_endpoint = my_endpoint + 1
        form_config['dn42_ip6'] = str(their_endpoint)

    # set my IPv6-LL endpoint
    form_config['my_dn42_ip6'] = str(my_endpoint)
    # update auto_tunnel_v6
    db['auto_tunnel_v6'] = v6_endpoint_id + 2

    assert contains('wg_pubkey', form_config)

    # generate my WG-key for the other peer
    my_priv_key = WireguardKey.generate()
    my_pub_key = my_priv_key.public_key()

    form_config['my_wg_pkey'] = str(my_priv_key)
    form_config['my_wg_pubkey'] = str(my_pub_key)

    # psk now
    if not contains('wg_psk', form_config):
        psk = WireguardKey.generate()
        form_config['wg_psk'] = str(psk)

    # fill WG related info
    curr_id = db['wg_auto_id']
    form_config['wg_dev_name'] = f"{db['wg_prefix_name']}{curr_id}"

    db['wg_auto_id'] = curr_id + 1
    form_config['my_wg_listen_port'] = db['wg_listen_port']

    assert contains('wg_listen_port', form_config)
    # cast str into int
    form_config['wg_listen_port'] = int(form_config['wg_listen_port'])


def render_wg_cfg(form_config: dict, local: bool, yml_template: Path):
    values = {
        'local': local,
        'wg_dev_name': form_config['wg_dev_name'],
        'wg_ipv6_addr': form_config['my_dn42_ip6'] if local else form_config['dn42_ip6'],
        'wg_listen_port': form_config['my_wg_listen_port'] if local else form_config['wg_listen_port'],
        'remote_port': form_config['wg_listen_port'] if local else form_config['my_wg_listen_port'],
        'remote_ip': form_config['dn42_ip6'] if local else form_config['my_dn42_ip6'],
        'wg_pkey': form_config['my_wg_pkey'] if local else form_config['wg_pubkey'],
        'wg_public_key_peer': form_config['wg_pubkey'] if local else form_config['my_wg_pubkey'],
        'psk_key': form_config['wg_psk'],
        'allowed_pfxs': form_config['prefixes']
    }

    with open(str(yml_template), 'r') as f:
        rdr_cfg = Template(f.read()).render(**values)

    return rdr_cfg


def gen_cert_cfg(form_config: dict, wg_template: Path, app: Flask):
    cert_name = Path(CERTS_PATH).joinpath(f"{form_config['cn']}.cert.pem")

    my_cfg = render_wg_cfg(form_config, True, wg_template)
    their_cfg = render_wg_cfg(form_config, False, wg_template)

    print(my_cfg)
    print('----')
    print(their_cfg)

    ca_cert = read_cert(CA_CERT)
    ca_key = read_privkey(CA_KEY)

    gen_sign_cert(str(cert_name), ca_key, ca_cert,
                  form_config['csr_obj'], their_cfg, my_cfg)

    return (Path(CERTS_PATH).joinpath(f"{form_config['cn']}.cert.pem"),
            None,
            Path(CERTS_PATH).joinpath("ca.cert.pem"))


def check_contains_client(local_ip: str):
    meta_db = db_get()

    if meta_db.contains_client(local_ip):
        raise ValueError(f'A peering is already made with {local_ip}')


def add_peering_in_db(form_config: dict):
    db = db_get().db

    check_contains_client(form_config['local_ip'])

    # shelve limitations: temp assignation then do real assignation into DB
    curr_clients = db['clients']
    curr_clients[form_config['local_ip']] = form_config
    db['clients'] = curr_clients

    # make sure new data is saved in the persistent storage
    db.sync()


def bird_config(form_config: dict) -> str:
    values = {
        'local_ip': form_config['local_ip'],
        'neighbor_ip': MY_AS_CONFIG['ip_endpoint'],
        'root_ca_name': Path(form_config['root_ca']).name,
        'cert_name': Path(form_config['cert_path']).name,
        'priv_key_name': Path(form_config['priv_key_path']).name,
        'remote_sni': MY_AS_CONFIG['sni'],
        'local_sni': form_config['sni'],
    }
    with open(BIRD_TEMPLATE, 'r') as f:
        bgp_bird_cfg = Template(f.read()).render(**values)

    return bgp_bird_cfg


def gen_cert_archive(form_config: dict):
    archive_name = generate_filename()
    archive_path = f'/tmp/{archive_name}'

    with ZipFile(archive_path, 'w') as zip_f:
        for cert_file in (form_config['cert_path'],
                          form_config['root_ca'],
                          form_config['priv_key_path']):
            zip_f.write(cert_file)

    return archive_path


def download_cert_archive(local_ip: str) -> SpooledTemporaryFile:
    db = db_get().db

    # XXX other peer can fetch someone else certificate (and priv key)...
    if local_ip not in db['clients']:
        raise ValueError('Not Found')

    client_peer = db['clients'][local_ip]

    tmp = SpooledTemporaryFile()
    with ZipFile(tmp, 'w', zipfile.ZIP_DEFLATED) as zip_f:
        for cert_file in (client_peer['cert_path'],
                          client_peer['root_ca'],
                          client_peer['priv_key_path']):
            zip_f.write(cert_file,
                        Path(cert_file).name)
    tmp.seek(0)

    return tmp


def gen_config(form_config: dict, app: Flask):
    # check_contains_client(form_config['local_ip'])
    fill_missing_fields(form_config)
    wg_conf_template = Path(app.root_path).joinpath(WG_TEMPLATE)

    cert, p_key, root_ca = gen_cert_cfg(form_config, wg_conf_template, app)

    form_config['cert_path'] = cert
    form_config['priv_key_path'] = p_key
    form_config['root_ca'] = root_ca

    add_peering_in_db(form_config)

    # now generate config required for the client
    # archive_path = gen_cert_archive(form_config)
    bird_bgp_cfg = bird_config(form_config)

    return bird_bgp_cfg
