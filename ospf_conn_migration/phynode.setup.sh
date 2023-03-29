#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

ip netns add node1
ip netns add node2
ip netns add node3

sysctl -w net.ipv4.udp_rmem_min=4096000 \
  net.core.rmem_max=26214400 \
  net.core.rmem_default=26214400 \
  net.core.netdev_max_backlog=2000

# Setup forwarding on intermediate node
ip netns exec node1 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node1 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"

# Keep IPv6 addr on link down event
ip netns exec node2 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node2 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node3 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node3 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"

# Increase UDP buffers on OSPF nodes
ip netns exec node2 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns exec node3 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"


# Create links
ip link add eth-n2 netns node1 type veth peer eth-n1 netns node2
ip link add eth-n3 netns node1 type veth peer eth-n1 netns node3
ip link add eth-n3 netns node2 type veth peer eth-n2 netns node3

# Bring loopback up
ip -n node1 link set dev lo up
ip -n node2 link set dev lo up
ip -n node3 link set dev lo up

# Alternative IP
ip -n node1 addr add cafe:13::1/64 dev eth-n3
ip -n node2 addr add cafe:23::2/64 dev eth-n3
ip -n node3 addr add cafe:13::3/64 dev eth-n1
ip -n node3 addr add cafe:23::3/64 dev eth-n2

# Bring interfaces up
ip -n node1 link set dev eth-n2 up
ip -n node1 link set dev eth-n3 up
ip -n node2 link set dev eth-n1 up
ip -n node2 link set dev eth-n3 up
ip -n node3 link set dev eth-n1 up
ip -n node3 link set dev eth-n2 up

# static routes for external node3
ip -n node1 -6 route add cafe:23::/64 via cafe:13::3 src cafe:13::1
ip -n node2 -6 route add cafe:13::/64 via cafe:23::3 src cafe:23::2


# GRE tunnel
ip -n node1 tunnel add tun-n3 mode gre remote cafe:23::2 local cafe:13::1 ttl 255
ip -n node1 tunnel add tun-n1 mode gre remote cafe:13::1 local cafe:23::2 ttl 255
