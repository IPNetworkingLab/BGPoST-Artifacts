#!/bin/bash

VARDIR="/dev/shm/tls_magic_ao"
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


function config() {
  local cfg_path="${__dir}/cfgs"
  local bird_cfgs="${cfg_path}/.dune/nodes"

  # setup network namespace
  "${__dir}/../perf_test/exec_dune_cmd.py" -a config -c "${cfg_path}/.dune/glutenfree"

  # generate certificates
  local gen_cert="${__dir}/../cert-generator/generate_certs.sh"
  mkdir -p "${cfg_path}/certs"
  for i in $(seq 1 2); do
    ${gen_cert} "${cfg_path}/certs" "rtr${i}" ED25519 "rtr${i}.rtr" "0.0.0.${i}" NULL NULL
    cp "${cfg_path}/certs/rtr${i}.cert.pem" "${VARDIR}/rtr${i}"
    cp "${cfg_path}/certs/rtr${i}.key" "${VARDIR}/rtr${i}"
  done

  # copy Root CA
  cp "${cfg_path}/certs/ca.cert.pem" "${VARDIR}"

  # copy bird configs
  for i in $(seq 1 2); do
    local rtr="rtr${i}"
    cp "${bird_cfgs}/${rtr}/${rtr}.bird.tls_magic_ao.conf" "${VARDIR}/${rtr}/${rtr}.conf"
  done
}

function start_bird() {
  local core_id=0

  for ns in rtr1 rtr2; do
    ip netns exec "${ns}" taskset -c ${core_id} "${BIRD}" \
        -fc "${VARDIR}/${ns}/${ns}.conf" \
        -s "${VARDIR}/${ns}/${ns}.sk" \
        -P "${VARDIR}/${ns}/${ns}.pid" > "${VARDIR}/${ns}/${ns}.std" 2>&1 &
    ((core_id = core_id + 2))
  done
}

function stop_bird() {
  for ns in rtr1 rtr2; do
    kill "$(cat "${VARDIR}/${ns}/${ns}.pid")"
  done
}

function destroy() {
  stop_bird

  for ns in rtr1 rtr2; do
    ip netns del "${ns}"
  done

  rm -rf "${VARDIR}"
}

function check_ns() {
  if ip netns exec rtr1 true > /dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}


case "${1}" in
  "config")
    if check_ns; then
      echo "Nothing to do"
      exit 0
    fi
    config
    ;;
  "start")
    if [ "${#}" -ne 2 ]; then
      echo "Usage: $0 start <bird_bin>"
      exit 1
    fi
    if ! check_ns; then
      echo "Topo not configured, please configure it first !"
      exit 1
    fi

    BIRD="${2}"
    start_bird
    ;;
  "stop")
    stop_bird
    ;;
  "destroy")
    destroy
    ;;
  *)
    echo "Usage $0 {config|start|stop|destroy}"
    exit 1
    ;;
esac
