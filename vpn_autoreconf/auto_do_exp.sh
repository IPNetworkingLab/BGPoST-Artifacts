#!/bin/bash

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# function file_name() {
#   local name="${1}"
#
#   if [[ -e "${name}" || -L "${name}" ]]; then
#     i=0
#     while [[ -e "${name}" || -L "${name}" ]]; do
#       ((i++))
#     done
#     name="${name}.${i}"
#   fi
#   echo "${name}"
# }


if [ "${EUID}" -ne "0" ]; then
  echo "Please run as root"
  exit 1
fi

if [ "$#" -ne 3 ]; then
  echo "usage: $0 {tcp|tls} <bird executable> <store exp dir>"
  exit 1
fi

BIRD="${1}"
MAIN_SCRIPT="${__dir}/setup.sh"
VARDIR="/dev/shm/autovpn_exp"
STORE_DIR="${2}"
SUFFIX=

mkdir -p "${STORE_DIR}"

if [ "${1}" = "tcp" ]; then
  SUFFIX="-tcp"
fi

for i in $(seq 1 30); do
  echo "Run ${i}/30"
  # destroy everything from a potential previous run
  ${MAIN_SCRIPT} "${BIRD}" destroy > /dev/null 2>&1

  # Now start the experiment
  ${MAIN_SCRIPT} "${BIRD}" "start${SUFFIX}"

  sleep 40

  # now graceful restart
  ${MAIN_SCRIPT} "${BIRD}" "reload${SUFFIX}"

  sleep 40

  ${MAIN_SCRIPT} "${BIRD}" stop

  # move BIRD logs of CE1 et PE1 to STORE_DIR (+ tcpdump)
  mv "${VARDIR}/ce1/ce1.log" "${STORE_DIR}/ce1.${i}.log"
  mv "${VARDIR}/pe1/pe1.ctrl_serv.log" "${STORE_DIR}/pe1.ctrl_serv.${i}.log"
  mv "${VARDIR}/pe1/pe1.log" "${STORE_DIR}/pe1.${i}.log"
  mv "${VARDIR}/pe1.pcapng" "${STORE_DIR}/pe1.${i}.pcapng"
done

echo "Done"
