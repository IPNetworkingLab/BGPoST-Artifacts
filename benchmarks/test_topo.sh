#!/bin/bash

if (( EUID != 0 )); then
    echo "Please run as root"
    exit 1
fi

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

WORK_DIR="/dev/shm/test_perf"
IPv4_PFX="172.16.0.0"
IPv6_PFX="fc01::"

function usage() {
  echo "$0 {config|cold_start {tcp|tls|tcp_ao|tcp_ao_tls}|start_bird {tcp|tls|tcp_ao|tcp_ao_tls}|stop_bird|destroy}"
  echo "  config: setup Netns, temp directory, etc."
  echo "  cold_start: start gobgp, inject full routing table and launch BIRD routers"
  echo "              with the corresponding config. See start_bird arguments."
  echo "  start_bird: launch BIRD router with the corresponding config. Current configs are:"
  echo "              tcp: BGP over plain TCP"
  echo "              tls: BGP over TLS/TCP"
  echo "              tcp_ao: BGP over plain TCP with AO TCP segment authentication"
  echo "              tcp_ao_tls: BGP over TLS with TCP AO authentication"
  echo "  destroy: "
  exit 1
}

function did_you_increase_udp_buffers() {
  # make this config system wide
  sysctl net.ipv4.udp_rmem_min=4096000
  sysctl net.ipv4.udp_wmem_min=4096000
  sysctl net.core.rmem_max=26214400
  sysctl net.core.wmem_max=26214400
  sysctl net.core.rmem_default=26214400
  sysctl net.core.wmem_default=26214400
  sysctl net.core.netdev_max_backlog=2000
}

function fetch_mrt_dump() {
  if test -f "${WORK_DIR}"/gobgp/mrt.dump; then
    # dump is already present
    return
  fi

  curl -L "https://data.ris.ripe.net/rrc01/2023.11/bview.20231115.0000.gz" -o - | \
     zcat > "$WORK_DIR"/gobgp/mrt.dump
}


function compute_ip() {
  local pfx=${1}
  local id=${2}

  python -c "from sys import argv; import ipaddress; print(ipaddress.ip_address(argv[1])+int(argv[2]))" "${pfx}" "${id}"
}

function new_rtr() {
  local rtr_name="${1}"

  ip netns add "${rtr_name}"
  ip -n "${rtr_name}" link set dev lo up

  # state dir
  mkdir -p "${WORK_DIR}/${rtr_name}"

  # increase UDP buffers
  ip netns exec "${rtr_name}" sysctl net.ipv4.udp_rmem_min=4096000
  ip netns exec "${rtr_name}" sysctl net.ipv4.udp_wmem_min=4096000

  # keep IPv6 addrs on link down
  ip netns exec "${rtr_name}" sysctl net.ipv6.conf.all.keep_addr_on_down=1

  # copy config
  cp "${__dir}/${TEST_TYPE}/${rtr_name}.conf" "${WORK_DIR}/${rtr_name}"
  # copy certificate & private key, also (even if not needed for the current test or router, but anyway...)
  if [ -f "${__dir}/certs/${rtr_name}.cert.pem" ]; then
    cp "${__dir}/certs/${rtr_name}.cert.pem" "${WORK_DIR}/${rtr_name}"
    cp "${__dir}/certs/${rtr_name}.key" "${WORK_DIR}/${rtr_name}"
  fi
}

function link_rtr() {
  local r1=${1}
  local r2=${2}
  local r1_id=${3}
  local r2_id=${4}

  ip link add "eth-${r2}" netns "${r1}" type veth peer "eth-${r1}" netns "${r2}"
  ip -n "${r1}" link set dev "eth-${r2}" up
  ip -n "${r2}" link set dev "eth-${r1}" up

  # add IPv4 & IPv6 on r1 node
  ip -n "${r1}" addr add "$(compute_ip "${IPv4_PFX}" "${r1_id}")/31" dev "eth-${r2}"
  ip -n "${r1}" addr add "$(compute_ip "${IPv6_PFX}" "${r1_id}")/127" dev "eth-${r2}"
  # add IPv4 & IPv6 on r2 node
  ip -n "${r2}" addr add "$(compute_ip "${IPv4_PFX}" "${r2_id}")/31" dev "eth-${r1}"
  ip -n "${r2}" addr add "$(compute_ip "${IPv6_PFX}" "${r2_id}")/127" dev "eth-${r1}"

  ip netns exec "${r1}" ./setup_delay.sh "eth-${r2}" 15ms 1000Mbit 25ms
  ip netns exec "${r2}" ./setup_delay.sh "eth-${r1}" 15ms 1000Mbit 25ms
}


function config_topo() {
  local gen_cert="${__dir}/../cert-generator/generate_certs.sh"
  # create routers & generate certs
  for i in $(seq 1 10); do
    new_rtr "rtr${i}"
    ${gen_cert} "${__dir}/certs" "rtr${i}" ED25519 "rtr${i}.rtr" "0.0.0.${i}" NULL NULL
  done
  new_rtr gobgp

  # put links between routers
  link_rtr gobgp rtr1 0 1
  link_rtr rtr10 rtr1 20 21

  local id=2
  for i in $(seq 1 9); do
    link_rtr "rtr${i}" "rtr$((i+1))" "$((id))" "$((id+1))"
    ((id=id+2))
  done

  # copy CA cert on WORK_DIR root
  cp "${__dir}/certs/ca.cert.pem" "$WORK_DIR"

  # fetch mrt dump for GoBGP
  fetch_mrt_dump
}


function start_gobgp() {
  ip netns exec gobgp \
    "${__dir}/gobgp.sh" "${GOBGP}" \
                        "${GOBGPD}" \
                        "$WORK_DIR"/gobgp/gobgp.conf \
                        "$WORK_DIR"/gobgp/mrt.dump \
                        "172.16.0.0" \
                        "fc01::" \
                        "eth-rtr1" \
                        "${WORK_DIR}/gobgp/gobgpd.pid"

}

function start_bird_rtr() {
  # make sure rtr1.mrt does not exist anymore
  if test -f "$WORK_DIR"/rtr1/rtr1.mrt; then
    echo "${WORK_DIR}/rtr1/rtr1.mrt still exists. Please move it. I will not start BIRD otherwise"
    exit 1
  fi

  # first make link rtr1 <--> gobgp down
  # the time all BIRD bgp sessions are established
  ip -n rtr1 link set dev eth-gobgp down

  local core_id=0

  # flush system wide metrics
  ip tcp_metrics flush all
  # and gobgp node
  ip -n gobgp tcp_metrics flush all
  for i in $(seq 1 10); do
    local ns="rtr${i}"

    # flush tcp metrics
    ip -n "${ns}" tcp_metrics flush all

    IO_QUIC_CORE_ID=$((core_id + 1)) ip netns exec "${ns}" \
    taskset --cpu-list "${core_id}" "${BIRD}" \
      -c "${WORK_DIR}/${ns}/${ns}.conf" \
      -s "${WORK_DIR}/${ns}/${ns}.sk" \
      -P "${WORK_DIR}/${ns}/${ns}.pid"
    ((core_id += 2))
  done

  # sessions should be established after 15s, I guess...
  sleep 15
  ip -n rtr1 link set dev eth-gobgp up

}

function change_exp_type() {
  local cfg_dir="${__dir}/${1}_cfg"

  # overwrite current config file contained
  # in the experiment state dir
  for i in $(seq 1 10); do
    local ns="rtr${i}"
    cp "${cfg_dir}/${ns}.conf" "${WORK_DIR}/${ns}"
  done
}


function cold_start() {
  # first start BIRD routers
  # as gobgp mrt injection takes
  # a lot of time...
  start_bird_rtr
  start_gobgp
}

function stop_gobgp() {
  local ns="gobgp"
  kill "$(cat "${WORK_DIR}/${ns}/${ns}d.pid")"
  rm -f "${WORK_DIR}/${ns}/${ns}d.pid"
}

function stop_bird_rtr() {
  for i in $(seq 1 10); do
    local ns="rtr${i}"
    kill "$(cat "${WORK_DIR}/${ns}/${ns}.pid")"
  done
}

function stop_all() {
  stop_gobgp
  stop_bird_rtr
}

function destroy() {
  stop_all

  for i in $(seq 1 10); do
    ip netns del "rtr${i}"
  done

  ip netns del gobgp
  rm -rf "$WORK_DIR"
}

function check_ns() {
  if ip netns exec rtr1 true > /dev/null 2>&1; then
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

function check_test_type() {
  case "$1" in
    "tcp")
    ;;
    "tls")
    ;;
    "tcp_ao_tls")
    ;;
    "tcp_ao")
    ;;
    "quic")
    ;;
    *)
      echo "Unsupported test type"
      exit 1
    ;;
  esac
}

did_you_increase_udp_buffers

# entry point
case "$1" in
  "config")
    if check_ns; then
      echo "Already configured. Nothing to do"
    else
      if [ "$#" -ne 2 ]; then
        echo "usage: $0 config <TEST_TYPE>"
        exit 1
      fi
      check_test_type "${2}"
      TEST_TYPE="${2}_cfg"
      config_topo
    fi
    ;;
  "cold_start")
    if [ "$#" -ne 4 ]; then
      echo "usage: $0 cold_start <gobgp_bin> <gobgpd_bin> <bird_bin>"
    fi

    if ! check_ns; then
      echo "Please configure first the topo !"
      exit 1
    fi

    GOBGP="${2}"
    GOBGPD="${3}"
    BIRD="${4}"

    cold_start
    ;;
  "start")
    if [ "$#" -ne 2 ]; then
      echo "usage: $0 start <bird_bin>"
    fi
    if ! process_exists "$(cat "${WORK_DIR}/gobgp/gobgpd.pid")"; then
      echo "GoBGPD is not running. Use cold_start for the first call !"
      exit 1
    fi

    BIRD="${2}"

    start_bird_rtr
    ;;
  "change_exp")
    if [ "$#" -ne 2 ]; then
      echo "usage: $0 change_exp <exp_type>"
      exit 1
    fi
    TEST_TYPE="${2}"
    check_test_type "${TEST_TYPE}"
    change_exp_type "${TEST_TYPE}"
    ;;
  "stop")
    stop_bird_rtr
    ;;
  "destroy")
    destroy
    ;;
   *)
    usage
    ;;
esac
