#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

ip netns add node1
ip netns add node2
ip netns add node3
ip netns add switch

sysctl -w net.ipv4.udp_rmem_min=4096000 \
  net.core.rmem_max=26214400 \
  net.core.rmem_default=26214400 \
  net.core.netdev_max_backlog=2000

# Setup forwarding on intermediate node
ip netns exec node3 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node3 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"

# Keep IPv6 addr on link down event
ip netns exec node2 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node2 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node3 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node3 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"

# Increase UDP buffers on OSPF nodes
ip netns exec node2 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns exec node3 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"


# Create links
ip link add eth-sw2 netns node1 type veth peer eth-n1 netns switch
ip link add eth-sw1 netns node2 type veth peer eth-n2 netns switch
ip link add eth-n3 netns node1 type veth peer eth-n1 netns node3
ip link add eth-n3 netns node2 type veth peer eth-n2 netns node3

# add delays
ip netns exec node1 bash -c "/tmp/delay.sh eth-sw2 15ms 1000mbit 15ms"
ip netns exec node1 bash -c "/tmp/delay.sh eth-n3 15ms 1000mbit 15ms"
ip netns exec node2 bash -c "/tmp/delay.sh eth-sw1 15ms 1000mbit 15ms"
ip netns exec node2 bash -c "/tmp/delay.sh eth-n3 15ms 1000mbit 15ms"
ip netns exec node3 bash -c "/tmp/delay.sh eth-n1 15ms 1000mbit 15ms"
ip netns exec node3 bash -c "/tmp/delay.sh eth-n2 15ms 1000mbit 15ms"

# Bring loopback up
ip -n node1 link set dev lo up
ip -n node2 link set dev lo up
ip -n node3 link set dev lo up
ip -n switch link set dev lo up

# Fix BIRD (https://bird.network.cz/pipermail/bird-users/2017-May/011240.html)
ip -n node1 addr add fe80::1/128 dev lo
ip -n node2 addr add fe80::1/128 dev lo

# Add loopback address
ip -n node1 addr add 1:5ee:bad:c0de::1/128 dev lo
ip -n node2 addr add 1:5ee:bad:c0de::2/128 dev lo

# Alternative IP
ip -n node1 addr add cafe:13::1/64 dev eth-n3
ip -n node2 addr add cafe:23::2/64 dev eth-n3
ip -n node3 addr add cafe:13::3/64 dev eth-n1
ip -n node3 addr add cafe:23::3/64 dev eth-n2

# Bring interfaces up
ip -n node1 link set dev eth-sw2 up
ip -n node1 link set dev eth-n3 up
ip -n node2 link set dev eth-sw1 up
ip -n node2 link set dev eth-n3 up
ip -n node3 link set dev eth-n1 up
ip -n node3 link set dev eth-n2 up

ip -n switch link add name br0 type bridge
ip -n switch link set dev br0 up

ip -n switch link set eth-n1 master br0
ip -n switch link set eth-n2 master br0

ip -n switch link set eth-n1 up
ip -n switch link set eth-n2 up

# configure wg tunnel
# node1
ip -n node1 link add dev wg-n2 type wireguard
ip netns exec node1 wg set wg-n2 listen-port 4241 private-key wg/node1.key
ip netns exec node1 wg set wg-n2 peer "$(cat wg/node2.pub)" \
	                 preshared-key wg/node-1-2.psk \
			 endpoint \[cafe:23::2\]:4242 \
			 allowed-ips ::/0
ip -n node1 addr add feca::1/64 dev wg-n2
ip -n node1 addr add fe80:bad:c0de::1/64 dev wg-n2

# node 2
ip -n node2 link add dev wg-n1 type wireguard
ip netns exec node2 wg set wg-n1 listen-port 4242 private-key wg/node2.key
ip netns exec node2 wg set wg-n1 peer "$(cat wg/node1.pub)" \
	                 preshared-key wg/node-1-2.psk \
		         endpoint \[cafe:13::1\]:4241 \
			 allowed-ips ::/0
ip -n node2 addr add feca::2/64 dev wg-n1
ip -n node2 addr add fe80:bad:c0de::2/64 dev wg-n1

sync && sleep 4 # wait kernel before inserting static routes

# static routes for external node3
ip -n node1 -6 route add cafe:23::/64 via cafe:13::3 src cafe:13::1
ip -n node2 -6 route add cafe:13::/64 via cafe:23::3 src cafe:23::2

ip -n node1 link set dev wg-n2 up
ip -n node2 link set dev wg-n1 up
