#!/bin/bash

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "${EUID}" -ne "0" ]; then
  echo "Please run as root"
  exit 1
fi

if [ "$#" -ne 2 ]; then
  echo "usage: $0 <bird executable> <store_dir>"
  exit 1
fi


BIRD="${1}"
MAIN_SCRIPT="${__dir}/setup.sh"
VARDIR="/dev/shm/multihomed_exp"
STORE_DIR="${2}"

function launch_exp() {
  # make sure everything is cleared from last run
  ${MAIN_SCRIPT} "${BIRD}" destroy > /dev/null 2>&1

  ${MAIN_SCRIPT} "${BIRD}" start

  sleep 30

  # now reroute
  ${MAIN_SCRIPT} "${BIRD}" reroute

  # then stop
  sleep 30
  ${MAIN_SCRIPT} "${BIRD}" stop
}


for i in $(seq 1 30); do
  echo "Run ${i}/30"
  launch_exp > /dev/null 2>&1
  mv "${VARDIR}/as2-r1/trace.pcapng" "${STORE_DIR}/multihomed.${i}.pcapng"
  sync
done