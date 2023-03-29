#! /bin/bash -xe

ip netns add gobgp
ip -n gobgp l set dev lo up
ip netns exec gobgp bash -c "ip a add fe80::/128 dev lo"
ip netns exec gobgp bash -c "bash /tmp/generate_certs.sh /tmp gobgp ED25519 gobgp 0.0.0.0 NULL /tmp/empty"
ip netns exec gobgp bash -c "sysctl -w net.ipv6.conf.default.forwarding=1"
ip netns exec gobgp bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec gobgp bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec gobgp bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000"
ip netns add rtr1
ip -n rtr1 l set dev lo up
ip netns exec rtr1 bash -c "ip a add fe80::/128 dev lo"
ip netns exec rtr1 bash -c "bash /tmp/generate_certs.sh /tmp rtr1 ED25519 rtr1 0.0.0.0 NULL /tmp/empty"
ip netns exec rtr1 bash -c "sysctl -w net.ipv6.conf.default.forwarding=1"
ip netns exec rtr1 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec rtr1 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec rtr1 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000"
ip netns add rtr2
ip -n rtr2 l set dev lo up
ip netns exec rtr2 bash -c "ip a add fe80::/128 dev lo"
ip netns exec rtr2 bash -c "bash /tmp/generate_certs.sh /tmp rtr2 ED25519 rtr2 0.0.0.0 NULL /tmp/empty"
ip netns exec rtr2 bash -c "sysctl -w net.ipv6.conf.default.forwarding=1"
ip netns exec rtr2 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec rtr2 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec rtr2 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000"
ip netns add rtr3
ip -n rtr3 l set dev lo up
ip netns exec rtr3 bash -c "ip a add fe80::/128 dev lo"
ip netns exec rtr3 bash -c "bash /tmp/generate_certs.sh /tmp rtr3 ED25519 rtr3 0.0.0.0 NULL /tmp/empty"
ip netns exec rtr3 bash -c "sysctl -w net.ipv6.conf.default.forwarding=1"
ip netns exec rtr3 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec rtr3 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec rtr3 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000"
ip netns add rtr4
ip -n rtr4 l set dev lo up
ip netns exec rtr4 bash -c "ip a add fe80::/128 dev lo"
ip netns exec rtr4 bash -c "bash /tmp/generate_certs.sh /tmp rtr4 ED25519 rtr4 0.0.0.0 NULL /tmp/empty"
ip netns exec rtr4 bash -c "sysctl -w net.ipv6.conf.default.forwarding=1"
ip netns exec rtr4 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec rtr4 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec rtr4 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000"
ip netns add rtr5
ip -n rtr5 l set dev lo up
ip netns exec rtr5 bash -c "ip a add fe80::/128 dev lo"
ip netns exec rtr5 bash -c "bash /tmp/generate_certs.sh /tmp rtr5 ED25519 rtr5 0.0.0.0 NULL /tmp/empty"
ip netns exec rtr5 bash -c "sysctl -w net.ipv6.conf.default.forwarding=1"
ip netns exec rtr5 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec rtr5 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec rtr5 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000"
ip netns add rtr6
ip -n rtr6 l set dev lo up
ip netns exec rtr6 bash -c "ip a add fe80::/128 dev lo"
ip netns exec rtr6 bash -c "bash /tmp/generate_certs.sh /tmp rtr6 ED25519 rtr6 0.0.0.0 NULL /tmp/empty"
ip netns exec rtr6 bash -c "sysctl -w net.ipv6.conf.default.forwarding=1"
ip netns exec rtr6 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec rtr6 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec rtr6 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000"
ip netns add rtr7
ip -n rtr7 l set dev lo up
ip netns exec rtr7 bash -c "ip a add fe80::/128 dev lo"
ip netns exec rtr7 bash -c "bash /tmp/generate_certs.sh /tmp rtr7 ED25519 rtr7 0.0.0.0 NULL /tmp/empty"
ip netns exec rtr7 bash -c "sysctl -w net.ipv6.conf.default.forwarding=1"
ip netns exec rtr7 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec rtr7 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec rtr7 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000"
ip netns add rtr8
ip -n rtr8 l set dev lo up
ip netns exec rtr8 bash -c "ip a add fe80::/128 dev lo"
ip netns exec rtr8 bash -c "bash /tmp/generate_certs.sh /tmp rtr8 ED25519 rtr8 0.0.0.0 NULL /tmp/empty"
ip netns exec rtr8 bash -c "sysctl -w net.ipv6.conf.default.forwarding=1"
ip netns exec rtr8 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec rtr8 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec rtr8 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000"
ip netns add rtr9
ip -n rtr9 l set dev lo up
ip netns exec rtr9 bash -c "ip a add fe80::/128 dev lo"
ip netns exec rtr9 bash -c "bash /tmp/generate_certs.sh /tmp rtr9 ED25519 rtr9 0.0.0.0 NULL /tmp/empty"
ip netns exec rtr9 bash -c "sysctl -w net.ipv6.conf.default.forwarding=1"
ip netns exec rtr9 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec rtr9 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec rtr9 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000"
ip netns add rtr10
ip -n rtr10 l set dev lo up
ip netns exec rtr10 bash -c "ip a add fe80::/128 dev lo"
ip netns exec rtr10 bash -c "bash /tmp/generate_certs.sh /tmp rtr10 ED25519 rtr10 0.0.0.0 NULL /tmp/empty"
ip netns exec rtr10 bash -c "sysctl -w net.ipv6.conf.default.forwarding=1"
ip netns exec rtr10 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec rtr10 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec rtr10 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000"
ip l add dev eth0 netns gobgp type veth peer name eth1 netns rtr1
ip netns exec gobgp bash -c "tc qdisc add dev eth0 root netem delay 5ms rate 40gbit"
ip -n gobgp l set dev eth0 mtu 9000
ip -n rtr1 l set dev eth1 mtu 9000
ip -n gobgp l set dev eth0 up
ip -n rtr1 l set dev eth1 up
ip l add dev eth2 netns rtr1 type veth peer name eth3 netns rtr2
ip netns exec rtr1 bash -c "tc qdisc add dev eth2 root netem delay 5ms rate 40gbit"
ip -n rtr1 l set dev eth2 mtu 9000
ip -n rtr2 l set dev eth3 mtu 9000
ip -n rtr1 l set dev eth2 up
ip -n rtr2 l set dev eth3 up
ip l add dev eth21 netns rtr1 type veth peer name eth20 netns rtr10
ip netns exec rtr1 bash -c "tc qdisc add dev eth21 root netem delay 5ms rate 40gbit"
ip -n rtr1 l set dev eth21 mtu 9000
ip -n rtr10 l set dev eth20 mtu 9000
ip -n rtr1 l set dev eth21 up
ip -n rtr10 l set dev eth20 up
ip l add dev eth4 netns rtr2 type veth peer name eth5 netns rtr3
ip netns exec rtr2 bash -c "tc qdisc add dev eth4 root netem delay 5ms rate 40gbit"
ip -n rtr2 l set dev eth4 mtu 9000
ip -n rtr3 l set dev eth5 mtu 9000
ip -n rtr2 l set dev eth4 up
ip -n rtr3 l set dev eth5 up
ip l add dev eth6 netns rtr3 type veth peer name eth7 netns rtr4
ip netns exec rtr3 bash -c "tc qdisc add dev eth6 root netem delay 5ms rate 40gbit"
ip -n rtr3 l set dev eth6 mtu 9000
ip -n rtr4 l set dev eth7 mtu 9000
ip -n rtr3 l set dev eth6 up
ip -n rtr4 l set dev eth7 up
ip l add dev eth8 netns rtr4 type veth peer name eth9 netns rtr5
ip netns exec rtr4 bash -c "tc qdisc add dev eth8 root netem delay 5ms rate 40gbit"
ip -n rtr4 l set dev eth8 mtu 9000
ip -n rtr5 l set dev eth9 mtu 9000
ip -n rtr4 l set dev eth8 up
ip -n rtr5 l set dev eth9 up
ip l add dev eth10 netns rtr5 type veth peer name eth11 netns rtr6
ip netns exec rtr5 bash -c "tc qdisc add dev eth10 root netem delay 5ms rate 40gbit"
ip -n rtr5 l set dev eth10 mtu 9000
ip -n rtr6 l set dev eth11 mtu 9000
ip -n rtr5 l set dev eth10 up
ip -n rtr6 l set dev eth11 up
ip l add dev eth12 netns rtr6 type veth peer name eth13 netns rtr7
ip netns exec rtr6 bash -c "tc qdisc add dev eth12 root netem delay 5ms rate 40gbit"
ip -n rtr6 l set dev eth12 mtu 9000
ip -n rtr7 l set dev eth13 mtu 9000
ip -n rtr6 l set dev eth12 up
ip -n rtr7 l set dev eth13 up
ip l add dev eth14 netns rtr7 type veth peer name eth15 netns rtr8
ip netns exec rtr7 bash -c "tc qdisc add dev eth14 root netem delay 5ms rate 40gbit"
ip -n rtr7 l set dev eth14 mtu 9000
ip -n rtr8 l set dev eth15 mtu 9000
ip -n rtr7 l set dev eth14 up
ip -n rtr8 l set dev eth15 up
ip l add dev eth16 netns rtr8 type veth peer name eth17 netns rtr9
ip netns exec rtr8 bash -c "tc qdisc add dev eth16 root netem delay 5ms rate 40gbit"
ip -n rtr8 l set dev eth16 mtu 9000
ip -n rtr9 l set dev eth17 mtu 9000
ip -n rtr8 l set dev eth16 up
ip -n rtr9 l set dev eth17 up
ip l add dev eth18 netns rtr9 type veth peer name eth19 netns rtr10
ip netns exec rtr9 bash -c "tc qdisc add dev eth18 root netem delay 5ms rate 40gbit"
ip -n rtr9 l set dev eth18 mtu 9000
ip -n rtr10 l set dev eth19 mtu 9000
ip -n rtr9 l set dev eth18 up
ip -n rtr10 l set dev eth19 up
IO_QUIC_CORE_ID=4 ip netns exec gobgp bash -c "taskset -c 5 ./bird -s /tmp/gobgp.bird.sk -c /tmp/gobgp.bird.conf -P /tmp/gobgp.bird.pid &"
IO_QUIC_CORE_ID=2 ip netns exec rtr1 bash -c "taskset -c 3 ./bird -s /tmp/rtr1.bird.sk -c /tmp/rtr1.bird.conf -P /tmp/rtr1.bird.pid &"
IO_QUIC_CORE_ID=10 ip netns exec rtr2 bash -c "taskset -c 11 ./bird -s /tmp/rtr2.bird.sk -c /tmp/rtr2.bird.conf -P /tmp/rtr2.bird.pid &"
IO_QUIC_CORE_ID=8 ip netns exec rtr3 bash -c "taskset -c 9 ./bird -s /tmp/rtr3.bird.sk -c /tmp/rtr3.bird.conf -P /tmp/rtr3.bird.pid &"
IO_QUIC_CORE_ID=6 ip netns exec rtr4 bash -c "taskset -c 7 ./bird -s /tmp/rtr4.bird.sk -c /tmp/rtr4.bird.conf -P /tmp/rtr4.bird.pid &"
IO_QUIC_CORE_ID=22 ip netns exec rtr5 bash -c "taskset -c 23 ./bird -s /tmp/rtr5.bird.sk -c /tmp/rtr5.bird.conf -P /tmp/rtr5.bird.pid &"
IO_QUIC_CORE_ID=20 ip netns exec rtr6 bash -c "taskset -c 21 ./bird -s /tmp/rtr6.bird.sk -c /tmp/rtr6.bird.conf -P /tmp/rtr6.bird.pid &"
IO_QUIC_CORE_ID=18 ip netns exec rtr7 bash -c "taskset -c 19 ./bird -s /tmp/rtr7.bird.sk -c /tmp/rtr7.bird.conf -P /tmp/rtr7.bird.pid &"
IO_QUIC_CORE_ID=16 ip netns exec rtr8 bash -c "taskset -c 17 ./bird -s /tmp/rtr8.bird.sk -c /tmp/rtr8.bird.conf -P /tmp/rtr8.bird.pid &"
IO_QUIC_CORE_ID=14 ip netns exec rtr9 bash -c "taskset -c 15 ./bird -s /tmp/rtr9.bird.sk -c /tmp/rtr9.bird.conf -P /tmp/rtr9.bird.pid &"
IO_QUIC_CORE_ID=12 ip netns exec rtr10 bash -c "taskset -c 13 ./bird -s /tmp/rtr10.bird.sk -c /tmp/rtr10.bird.conf -P /tmp/rtr10.bird.pid &"
