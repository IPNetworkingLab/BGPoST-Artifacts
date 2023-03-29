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

  #1. Launch tshark on alternative-link
  ip netns exec node1 tshark -qQ -i eth-n3 -w "${RESULT_DIR}"/node1."${i}".pcapng & 

  #2. Launch OSPF
  bash launch_ospf.quic.sh
  sleep 60
  #3. Trigger connection migration on eth-n3
  ip -n node1 link set dev eth-sw2 down
  sleep 20
  pkill tshark
  pkill bird
  sleep 2
done

