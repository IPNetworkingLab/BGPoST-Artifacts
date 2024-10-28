#!/usr/bin/env bash

REGENERATE=false
REMOVE_CA=false
PKEY_ALGO="ED25519"

function get_script_location() {
  SOURCE=${BASH_SOURCE[0]}
  while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR=$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)
    SOURCE=$(readlink "$SOURCE")
    [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  done
  cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd
}

function usage() {
  echo "usage: $0 [-f] [-] [-a <private key algo>] <output_dir>"
  echo "    -f: force regeneration of client certificate (not CA)"
  echo "    -c: force root CA regeneration (WARNING: implies -f)"
  echo "    -a <private key algo>: RSA or ED25519. Default ED25519"
  echo "    <output_dir>: directory where certificate will be generated"
}

while getopts 'a:fc' OPTION; do
  case "$OPTION" in
  f) REGENERATE=true ;;
  a) PKEY_ALGO=$OPTARG ;;
  c) REMOVE_CA=true; REGENERATE=true ;;
  *)
    echo "Unknown Option $OPTION"
    usage
    exit 1
    ;;
  esac
done
shift $((OPTIND - 1))

if [ "$#" -ne 1 ]; then
  usage
  exit 1
fi

OUTPUT_DIR=$1

if [ "$REMOVE_CA" = true ]; then
  echo "[INFO] Removing root CA"
  rm -f "$OUTPUT_DIR"/ca.cert.pem
fi

# Check if this script is needed
if [ -f "$OUTPUT_DIR"/ca.cert.pem ] &&
  [ -f "$OUTPUT_DIR"/node1.cert.pem ] &&
  [ -f "$OUTPUT_DIR"/node2.cert.pem ] &&
  ! "$REGENERATE" = true; then
  echo "Already generated! Nothing to do"
  exit 0
fi

NODE1_CFG="$(mktemp)"
NODE2_CFG="$(mktemp)"

# Put here config for Node1 (act as client)
cat <<EOF >"$NODE1_CFG"
{
  "description": "This session has been generated with the certificate",
  "remote_ip": "40.0.0.1",
  "local_ip": "40.0.0.2",
  "remote_as": 65001,
  "local_as": 65002,
  "afis": {
    "ipv4": {
      "unicast": {
        "rm-in": "rm-in",
        "rm-out": "rm-out"
      }
    }
  },
  "prefix-lists": {
    "pfx_name": [
      {
        "action": "permit",
        "prefix": "1.1.1.0/24",
        "le": 32,
        "ge": 25
      }
    ]
  },
  "route-maps": {
    "rm-in": {
      "50": {
        "action": "permit",
        "match": {
          "type": "ip address prefix-list",
          "name": "pfx_name"
        },
        "set": {
          "type": "local-preference",
          "value": 256
        }
      },
      "100": {
        "action": "deny"
      }
    },
    "rm-out": {
      "100": {
        "action": "permit"
      }
    }
  }
}
EOF

# Put here config for Node2
cat <<EOF >"$NODE2_CFG"
{
  "comment": "This is Node2 autoconfig"
}
EOF

# Generate node1 certificate
./generate_certs.sh "$OUTPUT_DIR" "node1" "$PKEY_ALGO" "node1" "42.0.0.1" "$NODE1_CFG"

# Generate node2 certificate
./generate_certs.sh "$OUTPUT_DIR" "node2" "$PKEY_ALGO" "node2" "42.0.0.2" "$NODE2_CFG"

# Clean our mess
rm -f "$NODE1_CFG" "$NODE2_CFG"
