#!/bin/bash

function usage() {
  echo "$0 <bird_exec> {start|stop|destroy}"
  return 1
}


if [ $# -ne 2 ]; then
  usage
fi

if [ $EUID -ne 0 ]; then
  echo "Please run as root"
  usage
fi


BIRD="$1"
VARDIR="/dev/shm/randy_lab"


function setup() {
  ip netns add randy_vm                                               
  ip netns add randy_rtr                                              

  ip link add eth0 netns randy_vm type veth peer eth0 netns randy_rtr

  ip -n randy_rtr link set dev lo up
  ip -n randy_vm link set dev lo up

  ip -n randy_vm addr add 198.180.150.60/24 dev eth0
  ip -n randy_rtr addr add 198.180.150.120/24 dev eth0

  ip -n randy_vm link set dev eth0 up
  ip -n randy_rtr link set dev eth0 up

  mkdir "${VARDIR}"

}

function check_ns() {
  if ip netns exec randy_vm true > /dev/null 2>&1; then
    return 0;
  else
    return 1;
  fi
}


function start() {
  if ! check_ns; then
    setup
  fi

  for ns in randy_vm randy_rtr; do
    ip netns exec "${ns}" tcpdump -Uni eth0 -w ${VARDIR}/${ns}.pcap &
    echo $! > ${VARDIR}/${ns}.tcpdump.pid

    ip netns exec "${ns}" "${BIRD}" -c ${ns}.conf \
                                    -s ${VARDIR}/${ns}.sk \
                                    -P ${VARDIR}/${ns}.pid
  done
}


function stop() {
  for ns in randy_vm randy_rtr; do
    kill "$(cat ${VARDIR}/${ns}.tcpdump.pid)"
    kill "$(cat ${VARDIR}/${ns}.pid)"
  done
}

function destroy() {
  stop
  for ns in randy_vm randy_rtr; do
    ip netns del ${ns}
  done
  rm -rf ${VARDIR}
}


case $2 in
  "start")
    start
    ;;
  "stop")
    stop
    ;;
  "destroy")
    destroy
    ;;
  *)
    usage
    ;; 
esac
