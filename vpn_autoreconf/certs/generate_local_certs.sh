#!/bin/bash

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GEN_CERT="${__dir}/../../cert-generator/generate_certs.sh"

DEST_DIR="${__dir}"
PKEY_ALG="ED25519"

if [ "$1" = "clean" ]; then
  echo "Tidying certificates"
  rm -f "${__dir}"/*.pem \
        "${__dir}"/*.key \
        "${__dir}"/*.srl
fi

## Certificate of CE1 for the session CE1 -- PE1
# The PE router will apply 50Mbps and 1ms latency
${GEN_CERT} "${DEST_DIR}" "ce1.50m" ${PKEY_ALG} \
  "ce1.rtr" "10.40.41.5" \
  "${__dir}"/../cert_cfgs/ce1.50m.yaml NULL

# Certificate of CE1 for the session CE1 -- PE1
# Limit bandwidth of 100Mbps on the PE router interface
${GEN_CERT} "${DEST_DIR}" "ce1.100m" ${PKEY_ALG} \
  "ce1.rtr" "10.40.41.5" \
  "${__dir}"/../cert_cfgs/ce1.100m.yaml NULL

# CE2 certificate
${GEN_CERT} "${DEST_DIR}" "ce2" ${PKEY_ALG} \
  "ce2.rtr" "10.40.41.7" \
  NULL NULL

# PE1 certificate # TODO add more than one IP
${GEN_CERT} "${DEST_DIR}" "pe1" ${PKEY_ALG} \
  "pe1.rtr" "10.40.41.4" \
  NULL NULL

# PE2 certificate
${GEN_CERT} "${DEST_DIR}" "pe2" ${PKEY_ALG} \
  "pe2.rtr" "10.40.41.6" \
  NULL NULL
