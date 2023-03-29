#!/usr/bin/env python3
from argparse import ArgumentParser
from datetime import datetime
from datetime import timezone, timedelta
from ipaddress import ip_address
from logging import critical
from math import log2, ceil

import base64
from typing import Union

import yaml
from cryptography.hazmat.primitives.asymmetric import ed25519
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from cryptography.x509 import CertificateSigningRequest, load_pem_x509_certificate, Certificate, load_pem_x509_csr, \
    SubjectAlternativeName, DNSName, IPAddress, UnrecognizedExtension
from cryptography.x509.oid import NameOID
from cryptography import x509
from cryptography.x509.oid import ObjectIdentifier

from cryptography.hazmat.primitives.serialization import load_pem_private_key


def gen_pem_pkey(out_file: str):
    key = ed25519.Ed25519PrivateKey.generate()

    with open(out_file, 'wb') as f:
        f.write(
            key.private_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PrivateFormat.PKCS8,
                encryption_algorithm=serialization.NoEncryption()
            )
        )

    return key


def read_privkey(in_file: str):
    with open(in_file, 'rb') as f:
        p_key = f.read()

    return load_pem_private_key(p_key,
                                password=None)


def read_cert(in_file: str) -> Certificate:
    with open(in_file, 'rb') as f:
        cert = f.read()

    return load_pem_x509_certificate(cert)


def read_csr(in_file: str) -> CertificateSigningRequest:
    with open(in_file, 'rb') as f:
        csr_pem = f.read()

    return load_pem_x509_csr(csr_pem)


def encode_local_cfg(value: bytes):
    enc_val = bytearray()
    len_val = len(value)

    # encode type
    enc_val += 0x0C.to_bytes(1, 'big')  # UTF8String type

    # encode length
    if len_val < 128:
        # short form
        enc_val += len_val.to_bytes(1, 'big')
    else:
        # compute the number of bytes needed to encode the "length value"
        ll = ceil((log2(len_val) / 8))
        len_of_len = (1 << 7) | (ll & 127)
        enc_len = len_val.to_bytes(ll, 'big')

        enc_val += len_of_len.to_bytes(1, 'big')
        enc_val += enc_len

    # encode value
    enc_val += value
    return bytes(enc_val)


def get_san_ip(cert_csr: CertificateSigningRequest):
    csr_san = cert_csr.extensions.get_extension_for_class(SubjectAlternativeName)

    csr_val = csr_san.value
    ips = csr_val.get_values_for_type(IPAddress)

    return ips


def get_names(cert_csr: CertificateSigningRequest):
    csr_san = cert_csr.extensions.get_extension_for_class(SubjectAlternativeName)
    csr_val = csr_san.value

    dns_names = csr_val.get_values_for_type(DNSName)

    cn = cert_csr.subject.get_attributes_for_oid(NameOID.COMMON_NAME)[0].value

    return cn, dns_names


class CSRBuild(object):
    def __init__(self, private_key):
        self.csr = x509.CertificateSigningRequestBuilder()
        self.key = private_key

    def csr_subject(self, cfg: dict):
        x509_name = []
        if 'cn' not in cfg:
            raise ValueError('"cn" field is missing (common name)')

        for oid_name, subject_part in ((NameOID.LOCALITY_NAME, 'locality'),
                                       (NameOID.COUNTRY_NAME, 'country'),
                                       (NameOID.STATE_OR_PROVINCE_NAME, 'state'),
                                       (NameOID.ORGANIZATION_NAME, 'organization'),
                                       (NameOID.COMMON_NAME, 'cn'),):
            if subject_part in cfg:
                x509_name.append(
                    x509.NameAttribute(oid_name, cfg[subject_part])
                )

        self.csr = self.csr.subject_name(x509.Name(x509_name))

    def csr_san(self, cfg: dict):
        x509_san = []

        if 'san' not in cfg:
            return

        for san in cfg['san']:
            try:
                ipa = ip_address(san)
                x509_san.append(
                    x509.IPAddress(ipa)
                )
            except ValueError:
                x509_san.append(
                    x509.DNSName(san)
                )

        self.csr = self.csr.add_extension(
            x509.SubjectAlternativeName(x509_san),
            critical=False
        )

    def csr_local_cfg(self, cfg: dict):
        if 'local-cfg' not in cfg:
            return

        local_cfg = yaml.dump(cfg['local-cfg'], stream=None)

        b64_cfg = base64.b64encode(local_cfg.encode('utf-8'))
        b64_cfg_enc = encode_local_cfg(b64_cfg)

        self.csr = self.csr.add_extension(
            x509.extensions.UnrecognizedExtension(
                oid=ObjectIdentifier('1.2.3.4'),
                value=b64_cfg_enc
            ),
            critical=False,
        )

    def csr_sign(self):
        self.csr = self.csr.sign(
            self.key,
            algorithm=None
        )

    def csr_pem(self):
        if not isinstance(self.csr, CertificateSigningRequest):
            ValueError("You must first sign the certificate (csr_sign) "
                       "before generating the PEM file !")

        return self.csr.public_bytes(
            serialization.Encoding.PEM
        )


class CSRSignBuild(object):
    def __init__(self, private_key: Ed25519PrivateKey,
                 ca_cert: Certificate, csr: CertificateSigningRequest):
        self._ca_cert = ca_cert
        self._csr = csr
        self._key = private_key
        self._cert = x509.CertificateBuilder()

    def cert_issuer(self):
        self._cert = self._cert.issuer_name(
            self._ca_cert.subject
        )

    def cert_subject(self):
        self._cert = self._cert.subject_name(
            self._csr.subject
        )

    def cert_pubkey(self):
        self._cert = self._cert.public_key(
            self._csr.public_key()
        )

    def cert_serial_number(self):
        self._cert = self._cert.serial_number(
            x509.random_serial_number()
        )

    def cert_valid(self, days=365):
        now = datetime.now(timezone.utc)
        self._cert = self._cert.not_valid_before(
            now
        ).not_valid_after(
            now + timedelta(days=days)
        )

    def cert_san(self):
        csr_ext = self._csr.extensions.get_extension_for_class(SubjectAlternativeName)
        csr_san = csr_ext.value
        if not isinstance(csr_san, SubjectAlternativeName):
            raise ValueError(f'WTF not SAN extension? Got: "{type(csr_san)}"')

        dns_names = csr_san.get_values_for_type(DNSName)
        ip_names = csr_san.get_values_for_type(IPAddress)

        # TODO check the validity if DNS and IP addresses for routers
        sans = [x509.DNSName(dns_name) for dns_name in dns_names]
        sans += [x509.IPAddress(ip) for ip in ip_names]

        self._cert = self._cert.add_extension(
            x509.SubjectAlternativeName(
                sans
            ),
            critical=False
        )

    def cert_constraints(self):
        self._cert = self._cert.add_extension(
            x509.BasicConstraints(ca=False, path_length=None),
            critical=True,
        )

    def cert_key_usage(self):
        self._cert = self._cert.add_extension(
            x509.KeyUsage(
                digital_signature=True,
                content_commitment=False,
                key_encipherment=True,
                data_encipherment=False,
                key_agreement=True,
                key_cert_sign=False,
                crl_sign=False,
                encipher_only=False,
                decipher_only=False
            ),
            critical=True
        )

    def cert_ext_key_usage(self):
        self._cert = self._cert.add_extension(
            x509.ExtendedKeyUsage([
                x509.ExtendedKeyUsageOID.CLIENT_AUTH,
                x509.ExtendedKeyUsageOID.SERVER_AUTH
            ]),
            critical=False
        )

    def cert_skid(self):
        self._cert = self._cert.add_extension(
            x509.SubjectKeyIdentifier.from_public_key(self._csr.public_key()),
            critical=False
        )

    def cert_akid(self):
        self._cert = self._cert.add_extension(
            x509.AuthorityKeyIdentifier.from_issuer_subject_key_identifier(
                self._ca_cert.extensions.get_extension_for_class(
                    x509.SubjectKeyIdentifier
                ).value
            ),
            critical=False
        )

    def cert_rtr_config(self, local=True, yml_cfg: Union[str | None] = None):
        if local and yml_cfg is None:
            try:
                local_cfg = self._csr.extensions.get_extension_for_oid(ObjectIdentifier('1.2.3.5'))
                self._cert = self._cert.add_extension(
                    local_cfg.value,
                    critical=False
                )
            except x509.ExtensionNotFound:
                # Too bad, no local config from peer
                pass
        else:
            if yml_cfg is None:
                raise ValueError("Missing YAML config")

            enc_cfg = encode_local_cfg(base64.b64encode(yml_cfg.encode('utf-8')))

            self._cert = self._cert.add_extension(
                UnrecognizedExtension(
                    oid=ObjectIdentifier('1.2.3.5' if local else '1.2.3.4'),
                    value=enc_cfg
                ),
                critical=False
            )

    def cert_sign(self):
        if isinstance(self._cert, Certificate):
            raise ValueError("The certificate is already signed !")

        self._cert = self._cert.sign(
            self._key,
            algorithm=None
        )

    def cert_pem(self) -> bytes:
        if not isinstance(self._cert, Certificate):
            raise ValueError('The certificate must be signed first!')

        return self._cert.public_bytes(
            encoding=serialization.Encoding.PEM
        )


class CSRDirector(object):
    def __init__(self, builder: CSRBuild, yml_cfg: dict):
        self.builder = builder
        self.yml_cfg = yml_cfg

    def construct_csr(self) -> bytes:
        # x509 extensions to add in the CSR
        self.builder.csr_subject(self.yml_cfg)
        self.builder.csr_san(self.yml_cfg)
        self.builder.csr_local_cfg(self.yml_cfg)

        self.builder.csr_sign()
        return self.builder.csr_pem()


class CertDirector(object):
    def __init__(self, builder: CSRSignBuild,
                 local_yml_cfg: Union[str | None],
                 remote_yml_cfg: Union[str | None]):
        self.builder = builder
        self.local_cfg = local_yml_cfg
        self.remote_cfg = remote_yml_cfg

    def construct_cert(self) -> bytes:
        self.builder.cert_issuer()
        self.builder.cert_subject()
        self.builder.cert_pubkey()
        self.builder.cert_serial_number()
        self.builder.cert_valid()
        self.builder.cert_san()
        self.builder.cert_constraints()
        self.builder.cert_key_usage()
        self.builder.cert_ext_key_usage()
        self.builder.cert_skid()
        self.builder.cert_akid()

        if self.local_cfg is not None:
            self.builder.cert_rtr_config(local=True, yml_cfg=self.local_cfg)

        if self.remote_cfg is not None:
            self.builder.cert_rtr_config(local=False, yml_cfg=self.remote_cfg)
        else:
            self.builder.cert_rtr_config()

        self.builder.cert_sign()
        return self.builder.cert_pem()


def gen_csr(out_file: str,
            key: ed25519.Ed25519PrivateKey,
            cfg: dict):
    builder = CSRBuild(key)
    director = CSRDirector(builder, cfg)

    pem_data = director.construct_csr()

    with open(out_file, 'wb') as f:
        f.write(pem_data)


def gen_sign_cert(out_file: str,
                  key: ed25519.Ed25519PrivateKey,
                  ca_cert: Certificate,
                  csr: CertificateSigningRequest,
                  local_cfg: str,
                  remote_cfg: Union[str | None] = None):
    builder = CSRSignBuild(key, ca_cert, csr)
    director = CertDirector(builder, local_cfg, remote_cfg)

    pem_data = director.construct_cert()

    with open(out_file, 'wb') as f:
        f.write(pem_data)


def main_csr(args):
    if args.in_key:
        key = read_privkey(args.in_key)
    else:
        key = gen_pem_pkey(args.out_key)

    with open(args.config, 'r') as f:
        cfg = yaml.safe_load(f)

    gen_csr(args.out_csr, key, cfg['csr'])


def main_sign(args):
    key = read_privkey(args.ca_key)
    ca = read_cert(args.ca_cert)
    csr = read_csr(args.csr)
    cfg = args.config if args.config is not None else None

    gen_sign_cert(args.out_file,
                  key, ca, csr, cfg)


def main(args):
    if args.which == 'csr':
        main_csr(args)
    elif args.which == 'sign':
        main_sign(args)
    else:
        ValueError('Cannot tell which main to call')


if __name__ == '__main__':
    parser = ArgumentParser(description="Build a CSR")

    subparsers = parser.add_subparsers(help="Generate CSR", required=True)

    csr_parser = subparsers.add_parser('csr', help="Build CSR")
    sign_parser = subparsers.add_parser('sign', help="Sign a CSR with a root CA key")

    # csr
    priv_key_parser = csr_parser.add_mutually_exclusive_group(required=True)

    priv_key_parser.add_argument('--out-key', dest='out_key', type=str,
                                 help='Generate a new Private Key and store it in the'
                                      'file given to this argument')
    priv_key_parser.add_argument('--in-key', dest='in_key', type=str,
                                 help='Load the private key to sign the CSR')

    csr_parser.add_argument('-c', '--config', dest='config', type=str, required=True,
                            help='Information to pass to the')
    csr_parser.add_argument('--out-csr', dest='out_csr', type=str, required=True,
                            help='Store the CSR on the path given to the argument')
    csr_parser.set_defaults(which='csr')

    # sign
    sign_parser.add_argument('-k', '--ca_key', dest='ca_key', required=True,
                             help='Private Key of the CA')
    sign_parser.add_argument('-s', '--ca_cert', dest='ca_cert', required=True,
                             help='CA PEM Cert')

    sign_parser.add_argument('-r', '--csr', dest='csr', required=True,
                             help='CSR to sign')

    sign_parser.add_argument('-c', '--config', dest='config', required=False,
                             help='Config for eventual additional config to pass to the '
                                  'certificate that will be signed')

    sign_parser.add_argument('-o', '--out-file', dest='out_file', required=True,
                             help='Store the signed certificate ')

    sign_parser.set_defaults(which='sign')

    _args = parser.parse_args()

    main(_args)
