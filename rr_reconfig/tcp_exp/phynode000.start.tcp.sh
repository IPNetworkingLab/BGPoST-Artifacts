#!/bin/bash

if [ "$EUID" -ne 0 ]; then
	echo "Please run as root"
	exit 1
fi

ROOT="/tmp/tcp_exp"

ip netns exec node000 bash -c "taskset -c 0 /tmp/bird -s /tmp/node000.bird.sk -c "${ROOT}"/node000.bird.cfg -P /tmp/node000.bird.pid &"
ip netns exec node001 bash -c "taskset -c 1 /tmp/bird -s /tmp/node001.bird.sk -c "${ROOT}"/node001.bird.cfg -P /tmp/node001.bird.pid &"
ip netns exec node002 bash -c "taskset -c 2 /tmp/bird -s /tmp/node002.bird.sk -c "${ROOT}"/node002.bird.cfg -P /tmp/node002.bird.pid &"
ip netns exec node003 bash -c "taskset -c 3 /tmp/bird -s /tmp/node003.bird.sk -c "${ROOT}"/node003.bird.cfg -P /tmp/node003.bird.pid &"
ip netns exec node004 bash -c "taskset -c 4 /tmp/bird -s /tmp/node004.bird.sk -c "${ROOT}"/node004.bird.cfg -P /tmp/node004.bird.pid &"


# ip netns exec node005 bash -c "sh "${ROOT}"/gobgp.sh node005"

