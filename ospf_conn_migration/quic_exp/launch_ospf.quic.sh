#!/bin/bash


if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# make sure no bird processes are running
pkill bird && sleep 2

ip -n node1 link set dev eth-sw2 up

ip netns exec node1 bash -c "/tmp/bird -f -s /tmp/bird.node1.sk -c /tmp/quic_exp/bird.node1.cfg -P /tmp/bird.node1.pid &"

ip netns exec node2 bash -c "/tmp/bird -f -s /tmp/bird.node2.sk -c /tmp/quic_exp/bird.node2.cfg -P /tmp/bird.node2.pid &"

