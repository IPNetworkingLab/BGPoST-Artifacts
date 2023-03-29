from re import sub
import socket
from ipaddress import ip_address


def get_id(nid: str):
    return int(sub('rtr', '', nid))


def get_id_ospf(nid: str):
    return int(sub('n', '', nid))


def id_to_ipv4(rid: int):
    return str(ip_address(rid))


def get_asn(nid: str):
    if nid == 'gobgp':
        return 6500
    else:
        return f'{65000 + get_id(nid)}'


def get_asn_ospf(nid: str):
    return f'{65000 + get_id_ospf(nid)}'


def get_addr(prefix: str):
    return prefix.split('/')[0]


def get_rid(nid: str) -> str:
    nid = get_id(nid)
    return socket.inet_ntop(socket.AF_INET, nid.to_bytes(4))


def get_passwd(nid1: str, nid2: str):
    l, r = min(nid1, nid2), max(nid1, nid2)
    return f"PWD_{l}-{r}_PWD"
