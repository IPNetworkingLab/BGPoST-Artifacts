#!/bin/bash

VARDIR="/dev/shm/anycast_topo"
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ulimit -n 5000

function global_sysctl() {
  sysctl net.core.rmem_max=7500000
  sysctl net.core.rmem_default=4259840
  sysctl net.core.wmem_max=5500000
  sysctl net.core.wmem_default=4259840
}

function config() {
  local cfg_path="${__dir}/cfgs"
  local gen_cfgs_path="${cfg_path}/.dune/nodes"
  local cnt=1


  # create & config ns and all var dirs
  "${__dir}/exec_dune_cmd.py" -c "${__dir}/cfgs/.dune/glutenfree" -a config

  ## Dune does not support adding static routes
  ip -n c1 route add default via 10.21.42.3
  ip -n c2 route add default via 10.21.42.5

  # add unicast address on http servers
  ip -n s1 addr add 192.0.2.1/32 dev lo
  ip -n s2 addr add 192.0.2.1/32 dev lo

  global_sysctl

  # then create certificate
  local gen_cert="${__dir}/../cert-generator/generate_certs.sh"
  mkdir -p "${cfg_path}/certs"
  for i in r1 r2 s1 s2; do
    if [ "${i}" = "s2" ]; then
      REMOTE_CFG="${__dir}/cfgs/r2_filter.yml"
    else
      REMOTE_CFG=NULL
    fi
    ${gen_cert} "${cfg_path}/certs" "${i}" ED25519 "${i}.rtr" "0.0.0.${cnt}" "${REMOTE_CFG}" NULL
    ((cnt += 1))
    cp "${cfg_path}/certs/${i}.cert.pem" "${VARDIR}/${i}"
    cp "${cfg_path}/certs/${i}.key" "${VARDIR}/${i}"
  done

  # copy routing config to the VARDIR folder
  for i in r1 r2 s1 s2; do
    cp "${gen_cfgs_path}/${i}/${i}.bird.conf" "${VARDIR}/${i}/${i}.conf"
  done

  # copy root ca
  cp "${cfg_path}/certs/ca.cert.pem" "${VARDIR}"

  ## # copy lighttpd config
  ## for i in s1 s2; do
  ##   cp "${gen_cfgs_path}/${i}/${i}.lighttpd.conf" "${VARDIR}/${i}"
  ## done
  ## # also copy 10kb.txt
  ## cp "${__dir}/10kb.txt" "${VARDIR}"

  # copy nsd config
  for i in s1 s2; do
    cp "${gen_cfgs_path}/${i}/${i}.nsd.conf" "${VARDIR}/${i}"
  done

  #copy zone file
  mkdir -p "${VARDIR}/zones"
  cp "${cfg_path}/test.zone" "${VARDIR}/zones"


  ## # set write permissions for lighttpd as not executed as root
  ## for i in s1 s2; do
  ##   chmod o+w "${VARDIR}/${i}"
  ## done

}

function start() {
  # start routing daemon
  for i in r1 r2 s1; do
    ip netns exec "${i}" "${BIRD}" \
       -fc "${VARDIR}/${i}/${i}.conf" \
       -s "${VARDIR}/${i}/${i}.sk" \
       -P "${VARDIR}/${i}/${i}.pid" > "${VARDIR}/${i}/${i}.std" 2>&1 &
  done

  # start control server for r2
  PYTHONPATH="${__dir}/.."  "${__dir}/control_server.py" \
      -s "${VARDIR}/r2/r2.ctrl_serv.sk" \
      -b "${VARDIR}/r2/r2.sk" \
      -c "${VARDIR}/r2/r2.conf" > "${VARDIR}/r2/r2.ctrl_serv.std" 2>&1 &
  # PID to file
  echo "$!" > "${VARDIR}/r2/r2.ctrl_serv.pid"

  # start one nsd replica
  local ns="s1"
  ip netns exec "${ns}" "${NSD}" -d \
    -c "${VARDIR}/${ns}/${ns}.nsd.conf" > "${VARDIR}/${ns}/${ns}.nsd.std" 2>&1 &

}

function start_s2() {
  local ns="s2"
  ip netns exec ${ns} "${BIRD}" \
    -fc "${VARDIR}/${ns}/${ns}.conf" \
    -s "${VARDIR}/${ns}/${ns}.sk" \
    -P "${VARDIR}/${ns}/${ns}.pid" > "${VARDIR}/${ns}/${ns}.std" 2>&1 &

  ip netns exec "${ns}" "${NSD}" -d \
    -c "${VARDIR}/${ns}/${ns}.nsd.conf" > "${VARDIR}/${ns}/${ns}.nsd.std" 2>&1 &
}

function stop() {
  for i in r1 r2 s1 s2; do
    kill "$(cat "${VARDIR}/${i}/${i}.pid")"
  done

  kill "$(cat "${VARDIR}/r2/r2.ctrl_serv.pid")"
  rm -f "${VARDIR}/r2/r2.ctrl_serv.pid"

  for i in s1 s2; do
    kill "$(cat "${VARDIR}/${i}/${i}.nsd.pid")"
  done
}

function start_ab() {
  for i in c1 c2; do
    ip netns exec "${i}" ab -c 250 \
        -n 50000 \
        -r -g "${VARDIR}/${i}/ab.${i}.tsv" \
        "http://192.0.2.1/" > /dev/null 2>&1 &
  done
}

function start_dnspyre() {
  local exp_type="${1}"
  local nb_concurrent=1

  if [ "${exp_type}" = "single" ]; then
    nb_concurrent=2000
  elif [ "${exp_type}" = "dual" ]; then
    nb_concurrent=4000
  else
    echo "Bad exp_type ${exp_type}. Expected single or dual"
    exit 1
  fi

  for i in c1 c2; do
    ip netns exec "${i}" "${DNSPYRE}" \
      -s "192.0.2.1" \
      -t A \
      -n 13 \
      -c "${nb_concurrent}" \
      --json \
      --csv="${VARDIR}/${i}/${i}.dnspyre.csv" \
      --plot "${VARDIR}/${i}" \
      --plotf svg \
      --precision=5 \
      --no-progress \
      "domain.test" > "${VARDIR}/${i}/${i}.dnspyre.log" 2>&1 &
  done
}

function destroy() {
  stop
  
  for ns in r1 r2 s1 s2 c1 c2; do
    ip netns del "${ns}"
  done

  rm -rf "${VARDIR}"
}

function check_ns() {
  if ip netns exec r1 true > /dev/null 2>&1; then
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
    if [ "${#}" -ne 3 ]; then
      echo "Usage: $0 start <bird_bin> <lighttpd_bin>"
      exit 1
    fi
    if ! check_ns; then
      echo "Topo not configured, please configure it first !"
      exit 1
    fi

    BIRD="${2}"
    NSD="${3}"
    start
    ;;
  "stop")
    stop
    ;;
  "destroy")
    destroy
    ;;
  "ab-test")
    start_ab
    ;;
  "dns-test")
    if [ "${#}" -ne 3 ]; then
      echo "usage: ${0} dns-test <dnspyre_bin> {single|dual}"
      exit 1
    fi
    DNSPYRE="${2}"
    start_dnspyre "${3}"
    ;;
  "start-s2")
    if [ "${#}" -ne 3 ]; then
      echo "usage: $0 start_s2 <bird_bin> <lighttpd_bin>"
      exit 1
    fi
    BIRD="${2}"
    NSD="${3}"
    start_s2
    ;;
  *)
    echo "Usage $0 {config|start|stop|destroy|ab-test|dns-test|start-s2}"
    exit 1
    ;;
esac
