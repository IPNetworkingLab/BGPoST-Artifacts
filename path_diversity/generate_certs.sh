#!/usr/bin/env bash

if [ -z "${1}" ]; then
    echo "This script should take the node_id as argument"
    exit 1
fi

CERT="${1}.cert.pem"
KEY="${1}.key"

if [ ! -f "${CERT}" ] || [ ! -f "${KEY}" ]; then
  # generate X.509 certs for QUIC
  echo "Generating X.509 certificates for ${1}"
  openssl req -new -newkey rsa:4096 \
      -x509 -sha256 -days 3650 -nodes \
      -subj "/C=US/ST=Some-State/L=MyCity/O=Dis/CN=${1}-cert" \
      -out "${CERT}" -keyout "${KEY}"
fi

unset CERT
unset KEY