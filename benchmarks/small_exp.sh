#!/bin/bash

if (( EUID != 0 )); then
    echo "Please run as root"
    exit 1
fi

if [ "$#" -ne 1 ]; then
  echo "$0 <MRT_SAVE_DIR>"
  echo " <MRT_SAVE_DIR> directory to save mrt dumps"
  exit 1
fi

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAR_DIR="/dev/shm/test_perf"
MAIN_SCRIPT="${__dir}/test_topo.sh"
SAVE_DIR="${1}"
BIRD_TCP="${2}"
BIRD_TLS="${3}"
BIRD_QUIC="${4}"
GOBGP="${5}"
GOBGPD="${6}"

mkdir -p "${SAVE_DIR}"


function do_exp() {
  local test_type="${1}"
  local bird_bin="${2}"
  # change BIRD config for the current experiment
  ${MAIN_SCRIPT} change_exp "${test_type}"

  # launch experiment
  ${MAIN_SCRIPT} start "${bird_bin}"
  sleep 140
  ${MAIN_SCRIPT} stop
  sleep 10
  mv "${VAR_DIR}"/rtr1/rtr1.mrt "${SAVE_DIR}/rtr1.${test_type}.mrt"
  sync
}

function batch_exp() {
  # first configure the test environment
  ${MAIN_SCRIPT} config tcp

  # do warmup with plain TCP
  # FIRST cold start (launch GoBGPD)
  ${MAIN_SCRIPT} cold_start "${GOBGP}" "${GOBGPD}" "${BIRD_TCP}"

  # stop all bird instances
  ${MAIN_SCRIPT} stop

  # make experiments
  do_exp tcp "${BIRD_TCP}"
  do_exp tcp_ao "${BIRD_TCP}"
  do_exp tls "${BIRD_TLS}"
  do_exp tls_ao "${BIRD_TLS}"
  do_exp quic "${BIRD_QUIC}"

  # clean our mess
  ${MAIN_SCRIPT} destroy
}