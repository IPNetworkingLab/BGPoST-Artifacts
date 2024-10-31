#! /bin/bash -xe

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

GENERATE_CERT="${SCRIPT_DIR}/../cert-generator/generate_certs.sh"

function gen_cert() {
  local pk_alg="ED25519"
  local cert_path="${1}"
  local rtr_name="${2}"
  local ip_rtr="${3}"
  local cert_name="${rtr_name}.cert.pem"

  if ! [ -d "${cert_path}" ]; then
    echo "'${cert_path}': No such directory"
    exit 1
  fi

  if [ -f "${cert_path}/${cert_name}" ]; then
    # Nothing to do
    return
  fi

  "${GENERATE_CERT}" "${cert_path}" "${rtr_name}" "${pk_alg}" "${rtr_name}" "${ip_rtr}" NULL NULL
}


git submodule update --init --recursive
docker build -t bgptls -f BGPoTLS/Dockerfile BGPoTLS
docker build -t gobgp -f Dockerfile.gobgp .

mkdir -p "${SCRIPT_DIR}/certs"

for i in $(seq 1 6); do
  gen_cert "${SCRIPT_DIR}/certs" "s${i}" "0.0.0.${i}"

  # Copy certificate and key to the node directory
  cp "${SCRIPT_DIR}/certs/s${i}.cert.pem" "${SCRIPT_DIR}/s${i}"
  cp "${SCRIPT_DIR}/certs/s${i}.key" "${SCRIPT_DIR}/s${i}"
  # also copy root ca to the node directory
  cp "${SCRIPT_DIR}/certs/ca.cert.pem" "${SCRIPT_DIR}/s${i}"
done

sudo containerlab deploy -t bgptls.clab.yml --reconfigure

