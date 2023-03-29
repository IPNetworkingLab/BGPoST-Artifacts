#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

if [ $# -ne 2 ]; then
  echo "Usage $0 <MAX_EXP> <RESULT_DIR>"
  exit 1
fi

MAX_EXP="$1"
RESULT_DIR="$2"

mkdir -p "${RESULT_DIR}"

for i in $(seq 1 "${MAX_EXP}"); do
  echo "Experiment ${i}/${MAX_EXP}"

  #0. Double check eth-sw2 up
  ip -n node1 link set dev eth-sw2 up

  #1. Launch OSPF
  bash launch_ospf.tcp.sh
  sleep 60
  #2. Trigger fallback on wg tunnel
  ip -n node1 link set dev eth-sw2 down
  sleep 20
  pkill bird
  sleep 2

  #3. collect logs
  mv /tmp/node1.log "${RESULT_DIR}"/node1."${i}".log
  mv /tmp/node2.log "${RESULT_DIR}"/node2."${i}".log
done

