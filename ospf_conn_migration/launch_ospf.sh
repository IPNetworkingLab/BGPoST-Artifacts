#!/bin/bash


if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# make sur no bird processes are running
pkill -KILL bird && sleep 2


ip netns exec node1 sysctl -w net.ipv6.conf.all.keep_addr_on_down=1
ip -n node1 link set dev eth-n2 up

ip netns exec node1 bash -c "/tmp/bird -f -s /tmp/bird.node1.sk -c /tmp/bird.node1.cfg -P /tmp/bird.node1.pid &"

ip netns exec node2 bash -c "/tmp/bird -f -s /tmp/bird.node2.sk -c /tmp/bird.node2.cfg -P /tmp/bird.node2.pid &"

