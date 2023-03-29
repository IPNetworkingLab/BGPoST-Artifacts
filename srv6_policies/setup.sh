#!/bin/bash

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VARDIR="/dev/shm/sr_topo"

if [ "${EUID}" -ne "0" ]; then
  echo "Please run as root"
  exit 1
fi

function config() {
  local cfg_path="${__dir}/cfgs"
  local bird_cfgs="${cfg_path}/.dune/nodes"

  # setup network namespaces
  "${__dir}/../perf_test/exec_dune_cmd.py" -a config -c "${cfg_path}/.dune/glutenfree"

  # copy OSPF config
  for i in $(seq 1 8); do
    local node="n${i}"
    cp "${bird_cfgs}/${node}/${node}.conf" "${VARDIR}/${node}/${node}.conf"
  done
}


function start_bird() {
  for i in $(seq 1 8); do
    local node="n${i}"
    ip netns exec "${node}"\
      "${BIRD}" -fc "${VARDIR}/${node}/${node}.conf" \
                -s "${VARDIR}/${node}/${node}.sk" \
                -P "${VARDIR}/${node}/${node}.pid" > "${VARDIR}/${node}/${node}.std" 2>&1 &
  done
}


function stop_bird() {
  for i in $(seq 1 8); do
    local node="n${i}"
    kill "$(cat "${VARDIR}/${node}/${node}.pid")"
  done
}


function destroy() {
  stop_bird

  for i in $(seq 1 8); do
    ip netns del "n${i}"
  done

  rm -rf "${VARDIR}"
}

function check_ns() {
  if ip netns exec n1 true > /dev/null 2>&1; then
    return 0;
  else
    return 1
  fi
}

case "${1}" in
  "config")
    if check_ns; then
      echo "Already configured, nothing to do"
      exit 0
    fi
    config
    ;;
  "start")
    if ! check_ns; then
      echo "Please configure the topo first !"
      exit 1
    fi
    if [ "${#}" -ne 2 ]; then
      echo "usage: ${0} start <bird_bin>"
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
    echo "usage: ${0} {config|start|stop|destroy}"
    ;;
esac