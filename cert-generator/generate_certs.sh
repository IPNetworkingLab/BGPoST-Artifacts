#!/usr/bin/env bash

set -e

if [ "$#" != "7" ]; then
  echo "This script takes 7 args."
  echo "$0 <dest_dir> <certificate_name> <pkey alg> <dns_name> <ip> <router_config> <router_local_config>"
  echo "   <dest_dir>: directory where certificate will be stored"
  echo "   <certificate_name>: prefix of the name (the suffixes .key,"
  echo "                       .csr, .cert.pem) will be automatically"
  echo "                       added by the script"
  echo "   <pkey alg>: either ED25519 or RSA"
  echo "   <dns_name>: certificate CN field"
  echo "   <ip>: IP address of the server on which the certificate"
  echo "         will be used"
  echo "   <router_config>: location of a file containing a remote configuration"
  echo "                    to be included in the generated certificate. NULL to skip this part."
  echo "   <router_local_config>: file containing the local config to apply to the router."
  echo "                          NULL to skip this part."
  exit 1
fi

DEST_DIR=$1
NAME=$2
PKEY_ALG=$3
COMMON_NAME=$4
ALT_NAME_IP=$5
CONFIG_RTR=$6
CONFIG_LOCAL_RTR=$7
PKEY_ALG_OPT=""

CA_KEY="$DEST_DIR"/ca.key
CA_CRT="$DEST_DIR"/ca.cert.pem
CA_CFG_FILE="$(mktemp)"

RTR_KEY="$DEST_DIR"/"$NAME".key
RTR_CSR="$DEST_DIR"/"$NAME".csr
RTR_CRT="$DEST_DIR"/"$NAME".cert.pem
RTR_CFG="$(mktemp)"

# CONFIG for V3_EXT
V3_EXT="$(mktemp)"

algo_check() {
  if [ "$1" = "RSA" ]; then
    PKEY_ALG_OPT+=" -pkeyopt rsa_keygen_bits:8192"
  elif [ "$1" = "ED25519" ]; then
    PKEY_ALG_OPT+=""
  else
    echo "Unknown algorithm. Got \"$1\". Expected \"RSA\" or \"ED25515\" (Names are case sensitive)"
    exit 1
  fi
}

# 0. First check algo
algo_check "$PKEY_ALG"

cat <<EOF > "$V3_EXT"
nsCertType = server, client
subjectKeyIdentifier = hash
#authorityKeyIdentifier = keyid,issuer:always
basicConstraints = CA:FALSE
keyUsage = critical, digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names
EOF

if [ "$CONFIG_RTR" != "NULL" ]; then
cat <<EOF >> "$V3_EXT"
1.2.3.4 = ASN1:UTF8String:"$(base64 -w0 < "$CONFIG_RTR")"
EOF
fi

if [ "$CONFIG_LOCAL_RTR" != "NULL" ]; then
cat <<EOF >> "$V3_EXT"
1.2.3.5 = ASN1:UTF8String:"$(base64 -w0 < "$CONFIG_LOCAL_RTR")"
EOF
fi

cat <<EOF >> "$V3_EXT"
[alt_names]
DNS.1 = $COMMON_NAME
DNS.2 = www.$COMMON_NAME
IP.1 = $ALT_NAME_IP
EOF

# Config for root CA
cat <<EOF > "$CA_CFG_FILE"
[ req ]
# Extension to add when the -x509 option is used.
x509_extensions     = v3_ca
distinguished_name  = req_distinguished_name
prompt = no

[ req_distinguished_name ]
countryName         = BE
stateOrProvinceName = "Brabant Wallon"
localityName        = "Louvain-la-Neuve"
organizationName    = "BGOoQUIC"
commonName          = "Router Root CA"
emailAddress        = thomas@thomas.thomas

[ v3_ca ]
# Extensions for a typical CA (man x509v3_config).
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
# extendedKeyUsage = clientAuth, emailProtection
EOF


# Config for Router Certificate
cat <<EOF > "$RTR_CFG"
[req]
distinguished_name = dn
prompt=no
req_extensions=req_ext

[dn]
C="BE"
ST="Brabant wallon"
O="Université catholique de Louvain"
CN="$COMMON_NAME"

[req_ext]
$(cat "$V3_EXT")
EOF

if [ ! -f "$CA_KEY" ]; then
  echo "No Root CA, generating one..."
  #1. Generate CA pkey
  openssl genpkey -algorithm "$PKEY_ALG" $PKEY_ALG_OPT > "$CA_KEY"
  #2. Generate Root CA
  openssl req -new -x509 -days 365 -key "$CA_KEY" -out "$CA_CRT" -config "$CA_CFG_FILE"
fi

#3. Generate rtr server key
openssl genpkey -algorithm "$PKEY_ALG" $PKEY_ALG_OPT > "$RTR_KEY"

#4. Generate signing request for rtr certificate
openssl req -new -key "$RTR_KEY" -out "$RTR_CSR" -config "$RTR_CFG"

#5. Sign rtr certificate with CA
openssl x509 -req -days 365 -in "$RTR_CSR" -CA "$CA_CRT" -CAkey "$CA_KEY" \
             -CAcreateserial -out "$RTR_CRT" -extfile "$V3_EXT"

#### Optionally verify crt
#openssl x509 -noout -text -in "$RTR_CRT"

# Clean our mess
rm "$CA_CFG_FILE" "$RTR_CFG" "$RTR_CSR" "$V3_EXT"
