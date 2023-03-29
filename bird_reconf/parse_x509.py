#!/usr/bin/env python3
import argparse
import ipaddress
import json
from typing import Union

from cryptography import x509
from cryptography.hazmat._oid import ExtensionOID
from cryptography.hazmat.backends import default_backend
from cryptography.x509 import Certificate
from cryptography.x509.oid import ObjectIdentifier


def decode_length(start_length: bytes) -> (int, int):
    length = start_length[0]
    if not ((length & 0x80) >> 7):
        real_length = length
        offset = 1
    else:
        len_length = length & 0x7F
        real_length = int.from_bytes(start_length[1: 1 + len_length], byteorder='big')
        offset = len_length

    return real_length, offset


def decode_string_val(utf8_string: bytes) -> str:
    assert utf8_string[0] == 0x0c, f"Wrong utf8_string format. Got {utf8_string[0]}. Expected 0x0c (or 12)"
    length, offset = decode_length(utf8_string[1:])
    return utf8_string[1 + offset:].decode()


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


def load_and_extract_field(cert_path: str, oid: str = "1.2.3.4") -> Union[dict | bytes]:
    with open(cert_path, 'rb') as f:
        pem_data = f.read()

    cert = x509.load_pem_x509_certificate(pem_data, default_backend())

    alt_name = cert.extensions.get_extension_for_oid(ExtensionOID.SUBJECT_ALTERNATIVE_NAME)
    print(decode_ip_from_subject_altname(alt_name.value.public_bytes()))

    json_extension = cert.extensions.get_extension_for_oid(ObjectIdentifier(oid))
    json_value = json_extension.value.public_bytes()

    value = decode_string_val(json_value)

    try:
        return json.loads(value)
    except json.decoder.JSONDecodeError:
        return value


def extract_field(cert: Certificate, oid: str = '1.2.3.4') -> bytes:
    oid_val = cert.extensions.get_extension_for_oid(ObjectIdentifier(oid))
    return oid_val.value.public_bytes()


def load_cert_from_bytes(pem_cert: bytes) -> Certificate:
    cert = x509.load_pem_x509_certificate(pem_cert, default_backend())
    return cert


def main(args):
    print(load_and_extract_field(args.cert))


# https://gist.github.com/sturadnidge/71cc9dbfbf1965faa4e6
# generate private key
# openssl genpkey -algorithm ED25519 > router.key
# generate ED25519 CSR
# openssl req -new -out router.csr -key router.key -config cfg.cfg
# self signing the CSR
# openssl x509 -req -days 700 -in router.csr -signkey router.key -out router.crt -extfile ext.v3
# print the certificate issued
# openssl x509 -in example.com.crt -text -noout
# cat router.key router.cert > router.pem
# extract public key
# openssl x509 -pubkey -noout -in router.pem  > router.pub

#### cfg.cfg
# [req]
# distinguished_name = dn
# prompt=no
# req_extensions=req_ext
#
# [dn]
# C="BE"
# ST="Brabant wallon"
# O="Université catholique de Louvain"
# CN="roq.info.ucl.ac.be"
#
# [req_ext]
# authorityKeyIdentifier=keyid,issuer
# basicConstraints=CA:FALSE
# keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
# extendedKeyUsage = serverAuth
# subjectAltName = @alt_names
# 1.2.3.4 = ASN1:UTF8String:"the string"
# [alt_names]
# DNS.1 = roq.info.ucl.ac.be
# IP.1 = 130.104.229.64


### ext.v3
# authorityKeyIdentifier=keyid,issuer
# basicConstraints=CA:FALSE
# keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
# extendedKeyUsage = serverAuth
# subjectAltName = @alt_names
# 1.2.3.4 = ASN1:UTF8String:"the string"
# [alt_names]
# DNS.1 = roq.info.ucl.ac.be
# IP.1 = 130.104.229.64

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-c', '--cert', dest='cert', required=True,
                        help='Certificate path')

    args_ = parser.parse_args()

    main(args_)

    # cert = x509.load_pem_x509_certificate(pem_data, default_backend())
