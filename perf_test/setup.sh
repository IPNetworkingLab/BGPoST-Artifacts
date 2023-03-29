#!/bin/bash

VARDIR="/dev/shm/test_perf"

ulimit -c unlimited
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Should we record per data for rtr1
ENABLE_PERF="yes"
# dune may not be in the target server
DUNE_REGENERATE="no"

IPv4_PFX="172.16.0.0"
IPv6_PFX="fc01::"

function compute_ip() {
  local pfx=${1}
  local id=${2}

  python -c "from sys import argv; import ipaddress; print(ipaddress.ip_address(argv[1])+int(argv[2]))" "${pfx}" "${id}"
}

function addr_addr_link() {
  local r1="${1}"
  local r2="${2}"
  local r1_id="${3}"
  local r2_id="${4}"
  local r1_iface="${5}"
  local r2_iface="${6}"

  ip -n "${r1}" addr add "$(compute_ip "${IPv4_PFX}" "${r1_id}")/31" dev "${r1_iface}"
  ip -n "${r1}" addr add "$(compute_ip "${IPv6_PFX}" "${r1_id}")/127" dev "${r1_iface}"

  ip -n "${r2}" addr add "$(compute_ip "${IPv4_PFX}" "${r2_id}")/31" dev "${r2_iface}"
  ip -n "${r2}" addr add "$(compute_ip "${IPv6_PFX}" "${r2_id}")/127" dev "${r2_iface}"
}

function config() {
  local cfg_path="${__dir}/cfgs"
  local gen_cfgs_path="${cfg_path}/.dune/nodes"

  # generate config
  if [ "${DUNE_REGENERATE}" = "yes" ]; then
    pushd "${cfg_path}" || exit 1
    dune -t perf_topo.yml || exit 1
    popd || exit 1
  fi

  # create & config ns and all var dirs
  "${__dir}/exec_dune_cmd.py" -c "${__dir}/cfgs/.dune/glutenfree" -a config

  # add ips to netns.. (this should be fixed with
  # latest DUNE fix)
  # addr_addr_link      gobgp rtr_inject 0 1 eth0 eth1
  # addr_addr_link rtr_inject rtr1       2 3 eth2 eth3
  # addr_addr_link       rtr1 rtr2       4 5 eth4 eth5
  # addr_addr_link       rtr2 rtr3       6 7 eth6 eth7

  # then create certificate
  local gen_cert="${__dir}/../cert-generator/generate_certs.sh"
  mkdir -p "${cfg_path}/certs"
  for i in $(seq 1 2); do
    ${gen_cert} "${cfg_path}/certs" "rtr${i}" ED25519 "rtr${i}.rtr" "0.0.0.${i}" NULL NULL
    cp "${cfg_path}/certs/rtr${i}.cert.pem" "${VARDIR}/rtr${i}"
    cp "${cfg_path}/certs/rtr${i}.key" "${VARDIR}/rtr${i}"
  done

  # copy root ca
  cp "${cfg_path}/certs/ca.cert.pem" "${VARDIR}"

  # copy config for static nodes
  cp "${gen_cfgs_path}/gobgp/gobgp.gobgp.conf" "${VARDIR}/gobgp/gobgp.conf"
  for ns in rtr_inject rtr3; do
    cp "${gen_cfgs_path}/${ns}/${ns}.bird.tcp.conf" "${VARDIR}/${ns}/${ns}.conf"
  done

  # fetch mrt
  "${__dir}/fetch_mrt.sh" "${VARDIR}/gobgp"
}


function check_exp() {
  case "$1" in
      "tcp"|"tls"|"quic"|"tls_ao"|"tcp_ao")
        return 0
        ;;
      *)
        echo "Bad exp ${exp}"
        exit  1
        ;;
  esac
}

function change_exp() {
  local exp=${1}
  local cfg_path="${__dir}/cfgs/.dune/nodes"

  check_exp "${exp}"

  for ns in rtr1 rtr2; do
    cp "${cfg_path}/${ns}/${ns}.bird.${exp}.conf" "${VARDIR}/${ns}/${ns}.conf"
  done
}

function start_bird() {
  local core_id=${1}

  for ns in "${@:2}"; do
    IO_QUIC_CORE_ID=$((core_id + 1)) ip netns exec "${ns}" \
        taskset -c "${core_id}" "${BIRD}" \
	      -fc "${VARDIR}/${ns}/${ns}.conf" \
              -s "${VARDIR}/${ns}/${ns}.sk" \
              -P "${VARDIR}/${ns}/${ns}.pid" > "${VARDIR}/${ns}/${ns}.std" 2>&1 &
    ((core_id = core_id + 2))
  done
}

function start() {
  start_bird "$@"

  sleep 2

  if [ "${ENABLE_PERF}" = "yes" ]; then
    # enable perf
    local rtr_id=1
    perf record -p "$(cat "${VARDIR}/rtr${rtr_id}/rtr${rtr_id}.pid")" -e cycles,instructions  --call-graph dwarf -o "${VARDIR}/rtr${rtr_id}/rtr${rtr_id}.record" &
    echo "$!" > "${VARDIR}/rtr${rtr_id}/rtr${rtr_id}.perf.pid"
  fi

  # start tshark on  rtr1
  ip netns exec rtr1 tshark -n -i eth4 -s 96 -w "${VARDIR}/rtr1/rtr1.pcapng" &
  echo "$!" > "${VARDIR}/rtr1/tshark.pid"
}

function cold_start() {
  # start plain bird routers
  start 6 rtr_inject

  # start gobgp
  ip netns exec gobgp \
    "${__dir}/gobgp.sh" "${GOBGP}" \
                        "${GOBGPD}" \
                        "${VARDIR}"/gobgp/gobgp.conf \
                        "${VARDIR}"/gobgp/mrt.dump \
                        "172.16.0.0" \
                        "fc01::" \
                        "eth0" \
                        "${VARDIR}/gobgp/gobgpd.pid"

}

function stop() {
  for ns in rtr1 rtr2 rtr3; do
    kill "$(cat "${VARDIR}/${ns}/${ns}.pid")"
  done

  # kill tshark
  kill "$(cat "${VARDIR}/rtr1/tshark.pid")"
  rm -f "${VARDIR}/rtr1/tshark.pid"

  # kill perf
  if [ "${ENABLE_PERF}" = "yes" ]; then
    kill "$(cat "${VARDIR}/rtr1/rtr1.perf.pid" )"
    rm -f "${VARDIR}/rtr1/rtr1.perf.pid"
  fi
}

function destroy() {

  stop

  for ns in gobgp rtr_inject rtr3; do
    kill "$(cat "${VARDIR}/${ns}/${ns}.pid")"
  done

  for ns in gobgp rtr_inject rtr1 rtr2 rtr3; do
    ip netns del "${ns}"
  done

  rm -rf "${VARDIR}"
}

function check_ns() {
  if ip netns exec gobgp true > /dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

function process_exists() {
  if [ -n "$(ps -p "${1}" -o pid=)" ]; then
    return 0
  fi
  return 1
}

case "$1" in
  "config")
    if check_ns; then
      echo "Already configured ! Nothing to do."
      exit 0
    fi
    config
    ;;
  "cold_start")
    if [ "$#" -ne 4 ]; then
      echo "usage: $0 cold_start <gobgp_bin> <gobgpd_bin> <bird_bin>"
      exit 1
    fi
    if ! check_ns; then
      echo "Topo not configured, Configuring it"
      config
    fi

    GOBGP="${2}"
    GOBGPD="${3}"
    BIRD="${4}"

    cold_start
    ;;
  "start")
    if [ "$#" -ne 3 ]; then
      echo "usage: $0 start <bird_bin> <birdc_bin>"
      exit 1
    fi

    if ! process_exists "$(cat "${VARDIR}/gobgp/gobgpd.pid")"; then
      echo "GoBGPD is not running. Use cold_start for the first call !"
      exit 1
    fi

    BIRD=${2}
    BIRDC=${3}

    ip -n rtr1 link set dev eth3 down

    # restart rtr-injecter (clear error state)
    ${BIRDC} -s "${VARDIR}/rtr_inject/rtr_inject.sk" << EOF
restart rtr1
EOF

    start 0 rtr1 rtr2 rtr3
    sleep 15
    ip -n rtr1 link set dev eth3 up
    ;;
  "change_exp")
    if [ "$#" -ne 2 ]; then
      echo "usage: $0 change_exp <exp_type>"
    fi
    change_exp "${2}"
    ;;
  "stop")
    stop
    ;;
  "destroy")
    destroy
    ;;
  *)
    echo "Todo USAGE"
    ;;
esac
