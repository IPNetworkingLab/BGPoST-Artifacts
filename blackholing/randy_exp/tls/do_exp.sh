#!/bin/bash

if [ ${EUID} -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

if [ "$#" -ne 4 ]; then
  echo "usage: $0 <bird_bin> <cert_dir> <listen_iface> <store dir>"
  echo "  <bird_bin> bird executable"
  echo "  <cert_dir> X.509 certificate dir"
  echo "  <listen_iface> name of the interface where BGP will establish the connection"
  echo "  <store dir> directory where to put the results of the experiments"
  exit 1
fi


__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SETUP="${__dir}/setup.sh"
BIRD="${1}"
CERT_DIR="${2}"
LISTEN_IFACE="${3}"

NB_EXP=30

VARDIR="/dev/shm/tls_blackhole"
STOREDIR="${4}"

function do_exp() {
  local exp_i="${1}"
  tcpdump -Uni "${LISTEN_IFACE}" -w "${VARDIR}/trace.pcap" &
  echo "$!" > "${VARDIR}/tcpdump.pid"

  # wait tcpdump start
  sleep 2

  # start BIRD on the node
  ${SETUP} start ingi "${BIRD}"
  # wait until route is propagated
  sleep 10

  # stop BIRD
  ${SETUP} stop ingi "${BIRD}"
  # stop tcpdump
  kill "$(cat "${VARDIR}/tcpdump.pid")"

  # Store & compress experiment result to persistent storage
  tar cf "${STOREDIR}/exp_run_${exp_i}.tar" "${VARDIR}"
  xz -z9e "${STOREDIR}/exp_run_${exp_i}.tar"

  # flush logs
  rm -f "${VARDIR}/ingi.log"

  # remove exp files
  rm -f "${VARDIR}/trace.pcap"
  rm -f "${VARDIR}/tls_blackhole.bbte.mrt"
  rm -f "${VARDIR}/tcpdump.pid"
}

function run_exp_batch() {
  # prepare experiment on host
  ${SETUP} setup ingi "${BIRD}" "${CERT_DIR}"
  mkdir -p "${STOREDIR}"

  for i in $(seq 1 ${NB_EXP}); do
    echo "Run ${i}/${NB_EXP}"
    do_exp "${i}"
  done
}


run_exp_batch
