import base64
from ipaddress import ip_address, ip_network

from cryptography.x509 import load_pem_x509_csr

from utils import contains
from x509_csr import read_csr, get_san_ip, get_names


def is_base64(b64: str):
    a = base64.b64encode(
        base64.b64decode(b64)).decode()
    return a == b64


def validate_as(asn: str):
    asn = int(asn)

    if asn == 0:
        raise ValueError("ASN Should not be 0")
    if asn > 0xffffffff:
        raise ValueError("ASN should be encoded in 32 bit integer")


def validate_ip(ip: str):
    """
    Raises ValueError if ip is not a valid IP address
    """
    ip_address(ip)


def validate_ip_prefix(pfx: str):
    ip_network(pfx)


def validate_tunnel_ipv6(ip: str):
    tun_ip = ip_address(ip)

    if not tun_ip.is_link_local:
        raise ValueError(f"{ip} is not a link local IP")


def validate_wg_psk_pubkey(psk: str):
    if not is_base64(psk):
        raise ValueError("Wireguard is not base64 encoded")


def validate_form(form_data):
    print(form_data)
    if not contains('local_asn', form_data):
        raise ValueError("You must provide your Local AS number")
    validate_as(form_data['local_asn'])

    if contains('dn42_ip6', form_data):
        validate_tunnel_ipv6(form_data['dn42_ip6'])
    if contains('wg_psk', form_data):
        validate_wg_psk_pubkey(form_data['wg_psk'])
    if not contains('wg_pubkey', form_data):
        raise ValueError('You must provide your wireguard public key')

    if not contains('wg_listen_port', form_data):
        raise ValueError('The Wireguard listen port should be filled')

    if not (0 < int(form_data['wg_listen_port']) < 65536):
        raise ValueError('Bad listen port')

    validate_wg_psk_pubkey(form_data['wg_pubkey'])

    if not contains('prefixes', form_data):
        raise ValueError("You must enter at least one prefix you want advertise !")

    for pfx in form_data['prefixes']:
        validate_ip_prefix(pfx)

    if not contains('csr', form_data):
        raise ValueError("You must provide a CSR")

    csr = load_pem_x509_csr(form_data['csr'].encode('utf-8'))
    form_data['csr_obj'] = csr
    ips = get_san_ip(csr)
    if len(ips) == 0:
        raise ValueError('The CSR should contain at least one IP in the SAN extension')

    for ip in ips:
        validate_ip(str(ip))

    form_data['ips'] = ips

    cn, dns_names  = get_names(csr)
    form_data['cn'] = cn
    form_data['dns'] = dns_names
