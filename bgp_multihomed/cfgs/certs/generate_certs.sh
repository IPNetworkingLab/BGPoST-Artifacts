#!/bin/bash


__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CERT_GENERATOR="${__dir}/../../../cert-generator/generate_certs.sh"

# certificate for client (as if received from its provider)
${CERT_GENERATOR} "${__dir}" as1-r1 ED25519 \
       as1-r1.infra 192.168.68.1 \
       "${__dir}/../certs_cfgs/as1-r1.remote_config.yaml" \
       "${__dir}/../certs_cfgs/as1-r1.local_config.yaml"

# AS2 is the provider so no particular config, will be config when client send its cert
${CERT_GENERATOR} "${__dir}" as2-r1 ED25519 as2-r1.infra 192.168.68.2 NULL NULL