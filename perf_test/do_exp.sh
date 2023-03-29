#!/bin/bash

VARDIR="/dev/shm/test_perf"
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SCRIPT="${__dir}/setup.sh"


if [ "${EUID}" -ne "0" ]; then
  echo "Please run as root"
  exit 1
fi

if [ "${#}" -ne 4 ]; then
  echo "usage: $0 <store_dir> <bird> <birdc> <bird_quic>"
  exit 1
fi

STORE_DIR="${1}"
BIRD="${2}"
BIRDC="${3}"
BIRD_QUIC="${4}"

mkdir -p "${STORE_DIR}"

## assume config & cold_start already made

## TODO put here config & cold start

echo "experiment,input,output,handshake,tshark" > "${STORE_DIR}/exps.csv"

for type in tcp tcp_ao tls tls_ao; do
  # Switch experiment
  ${MAIN_SCRIPT} change_exp ${type}
  for i in $(seq 1 5); do
    echo "${type}: ${i}/5"
    ${MAIN_SCRIPT} start "${BIRD}" "${BIRDC}"
    sleep 120
    ${MAIN_SCRIPT} stop
    sleep 5

    # copy mrts to store dir
    mv "${VARDIR}/rtr1/rtr1.mrt" "${STORE_DIR}/rtr1.${type}.${i}.mrt"
    mv "${VARDIR}/rtr2/rtr2.mrt" "${STORE_DIR}/rtr2.${type}.${i}.mrt"
    mv "${VARDIR}/rtr3/rtr3.mrt" "${STORE_DIR}/rtr3.${type}.${i}.mrt"
    mv "${VARDIR}/rtr1/rtr1.pcapng" "${STORE_DIR}/rtr1.${type}.${i}.pcapng"
    echo "${type},rtr1.${type}.${i}.mrt,rtr3.${type}.${i}.mrt,rtr2.${type}.${i}.mrt,rtr1.${type}.${i}.pcapng" >> "${STORE_DIR}/exps.csv"
    sync
  done
done

# do exp for QUIC in separated loop as this is not the same executable
${MAIN_SCRIPT} change_exp quic
type="quic"
for i in $(seq 1 5); do
  echo "${type}: ${i}/5"
  ${MAIN_SCRIPT} start "${BIRD_QUIC}" "${BIRDC}"
  sleep 120
  ${MAIN_SCRIPT} stop
  sleep 5

  # copy mrts to store dir
  mv "${VARDIR}/rtr1/rtr1.mrt" "${STORE_DIR}/rtr1.${type}.${i}.mrt"
  mv "${VARDIR}/rtr2/rtr2.mrt" "${STORE_DIR}/rtr2.${type}.${i}.mrt"
  mv "${VARDIR}/rtr3/rtr3.mrt" "${STORE_DIR}/rtr3.${type}.${i}.mrt"
  mv "${VARDIR}/rtr1/rtr1.pcapng" "${STORE_DIR}/rtr1.${type}.${i}.pcapng"
  echo "${type},rtr1.${type}.${i}.mrt,rtr3.${type}.${i}.mrt,rtr2.${type}.${i}.mrt,rtr1.${type}.${i}.pcapng" >> "${STORE_DIR}/exps.csv"
  sync
done
