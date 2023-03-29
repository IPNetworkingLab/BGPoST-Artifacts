import subprocess as sp
import socket

ASN_BASE = 65000


def ip(cmd: str, dry: bool = False):
    cmd = 'ip %s' % cmd
    if dry:
        print(cmd)
        return None
    else:
        return sp.run(cmd, capture_output=True, shell=True)


def id_expension(node_id: int) -> str:
    """ Convert a node id in its textual representation.
        @param[in]  node_id  The node ID.
        @return         The textual representation of @p node_id.
    """
    return str(node_id).zfill(3)


def id_to_name(node_id: int, phy: bool = False) -> str:
    """ Convert a node id in its corresponding name.
        @param[in]  node_id The node ID to convert.
        @param[in]  phy     True if the node is a physical one, else False.
        @return             The textual representation of the node name.
    """
    return '%snode%s' % ('phy' if phy else '', id_expension(node_id))


def id_from_name(node_name: str, phy: bool = False) -> int:
    return int(node_name.split('%snode' % ('phy' if phy else ''))[-1])


def node_exec(node_id: int, cmd: str):
    node_name = id_to_name(node_id)
    return ip('netns exec %s bash -c "%s"' % (node_name, cmd))


def lo_from_id(node_id: int) -> str:
    lo = bytes.fromhex(hex(((0xfc00 << 48) + (1 << 32) + (node_id << 16)) << 64)[2:])
    lo = socket.inet_ntop(socket.AF_INET6, lo)
    return lo


""" Get ip from integer representation """


def ip_from_int(ip: int, v6: bool = False) -> str:
    af = socket.AF_INET6 if v6 else socket.AF_INET
    n_bytes = 16 if v6 else 4
    return socket.inet_ntop(af, ip.to_bytes(n_bytes, 'big'))


def v4_from_int(ip: int) -> str:
    return ip_from_int(ip)


def v6_from_int(ip: int) -> str:
    return ip_from_int(ip, True)


def get_asn(node_id: int):
    return ASN_BASE + node_id
