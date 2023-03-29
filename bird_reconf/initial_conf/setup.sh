#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

if [ "$#" -ne 1 ]; then
  echo "This script should take the path to the BIRD executable"
  exit 1
fi

BIRD="$1"
VARDIR="/dev/shm/multihoming_reconf"

function setup_exp() {
  if ip netns exec rtr1 true > /dev/null  2>&1; then
    return 0;
  fi

  ip netns add rtr1
  ip netns add rtr2

  ip -n rtr1 link set dev lo up
  ip -n rtr2 link set dev lo up

  ip link add eth-rtr1 netns rtr2 type veth peer eth-rtr2 netns rtr1

  ip -n rtr1 addr add 10.0.0.1/24 dev eth-rtr2
  ip -n rtr2 addr add 10.0.0.2/24 dev eth-rtr1

  ip -n rtr1 link set dev eth-rtr2 up
  ip -n rtr2 link set dev eth-rtr1 up


  mkdir -p "${VARDIR}" 
  cp *.pem *.key *.conf "${VARDIR}"
}

setup_exp || (echo "Failed to setup ns" && exit 1)

for rtr in rtr1 rtr2; do
  ip netns exec ${rtr} "${BIRD}" -fc "${VARDIR}/${rtr}.conf" \
                           -s "${VARDIR}/${rtr}.bird.sk" \
                           -P "${VARDIR}/${rtr}.bird.pid" &
done

