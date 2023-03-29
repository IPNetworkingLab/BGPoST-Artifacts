import base64
import selectors
import socket
import struct
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Callable

from cryptography import x509
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.bindings._rust import ObjectIdentifier
from cryptography.x509 import Certificate, ExtensionNotFound

TYPE_CERT = 2
TYPE_CERT_LOCAL = 3


@dataclass
class SocketConfig(object):
    context: object
    pid: int
    sel: selectors.BaseSelector
    control_socket_path: str
    on_sk_event: callable
    on_cert_recv: Callable[[Certificate, str, object, int], bool]


def print_time(msg: str):
    curr_time = datetime.now()
    str_time = curr_time.strftime("%F %T.%f")
    print(f"{str_time} {msg}")


def decode_length(start_length: bytes) -> (int, int):
    length = start_length[0]
    if not ((length & 0x80) >> 7):
        real_length = length
        offset = 1
    else:
        len_length = length & 0x7F
        offset = 1
        real_length = int.from_bytes(start_length[1: 1 + len_length], byteorder='big')
        offset += len_length

    return real_length, offset


def decode_utf8_string(utf8_string: bytes) -> str:
    assert utf8_string[0] == 0x0c, f"Wrong utf8_string format. Got {utf8_string[0]}. Expected 0x0c (or 12)"
    length, offset = decode_length(utf8_string[1:])
    return utf8_string[1 + offset:].decode()


def load_cert_from_bytes(pem_cert: bytes, identifier: str) -> (Certificate, str):
    cert = x509.load_pem_x509_certificate(pem_cert, default_backend())

    oid_custom_config = ObjectIdentifier(identifier)
    try:
        config_field = cert.extensions.get_extension_for_oid(oid_custom_config)
    except ExtensionNotFound:
        return None, None

    b64_local_config = decode_utf8_string(config_field.value.public_bytes())
    local_config = base64.b64decode(b64_local_config).decode()

    return cert, local_config


def read_bird(sock: 'socket.socket', sock_conf: SocketConfig, mask: int):
    data = sock.recv(4096)
    if data:
        data_offset = 0
        data_len = len(data)
        while data_len:
            type_val = data[data_offset]
            length = int.from_bytes(data[data_offset + 1:data_offset + 3], byteorder='big')
            data_len -= length + 3  # 1 byte: type + 2 bytes: uint16 length
            assert data_len >= 0, "Certificate truncated, FIXME!!"
            value = data[data_offset + 2:data_offset + 2 + length]
            data_offset += length + 3
            if type_val == TYPE_CERT or type_val == TYPE_CERT_LOCAL:
                print_time(f"Received certificate from PID#{sock_conf.pid} ({type_val})")

                crt, rtr_conf = load_cert_from_bytes(value, "1.2.3.4" if type_val == TYPE_CERT else "1.2.3.5")
                if crt is not None or rtr_conf is not None:
                    if not sock_conf.on_cert_recv(crt, rtr_conf,
                                                  sock_conf.context, type_val):
                        print(f"Failed to reconfigure PID#{sock_conf.pid}")
                    else:
                        print_time(f"Reconfiguration of PID#{sock_conf.pid} succeeded")

    else:
        sock_conf.sel.unregister(sock)
        sock.close()


def accept(sock: 'socket.socket', config: SocketConfig, mask: int):
    conn, addr = sock.accept()
    creds = conn.getsockopt(socket.SOL_SOCKET, socket.SO_PEERCRED, struct.calcsize("3i"))
    pid, uid, gid = struct.unpack('3i', creds)
    print(f"Incoming connection from PID #{pid} (uid:{uid} gid:{gid})")
    conn.setblocking(False)

    sock_config = SocketConfig(
        context=config.context,
        pid=pid,
        on_sk_event=read_bird,
        on_cert_recv=config.on_cert_recv,
        control_socket_path=config.control_socket_path,
        sel=config.sel
    )

    config.sel.register(conn, selectors.EVENT_READ, sock_config)


def check_old_instance(control_socket: Path):
    if control_socket.exists():
        sk = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM, 0)
        try:
            sk.connect(str(control_socket))
            sk.close()
            return True
        except OSError:
            # OK, no servers are listening
            control_socket.unlink()
            return False
    else:
        return False


def io_loop(server_config: SocketConfig):
    if check_old_instance(Path(server_config.control_socket_path)):
        raise RuntimeError(f"Another server is listening to {server_config.control_socket_path}")

    server_fd = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM, 0)
    server_fd.setblocking(False)

    server_fd.bind(server_config.control_socket_path)
    server_fd.listen(256)

    server_config.sel.register(server_fd, selectors.EVENT_READ, server_config)

    print(f"Server started and ready to accept connections from "
          f"{server_config.control_socket_path}")
    while True:
        events = server_config.sel.select()
        for key, mask in events:
            sk_cfg = key.data
            sk_cfg.on_sk_event(key.fileobj, sk_cfg, mask)
