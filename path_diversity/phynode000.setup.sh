#! /bin/bash -x

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

ROOT=/tmp

sysctl -w net.ipv4.udp_rmem_min=4096000 \
          net.core.rmem_max=26214400 \
          net.core.rmem_default=26214400 \
          net.core.netdev_max_backlog=2000

ip netns add node000
ip -n node000 a add fe80::1/64 dev lo
ip -n node000 a add fc00:1:: dev lo
ip -n node000 l set dev lo up
ip netns exec node000 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node000 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node000 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node000 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node000 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node001
ip -n node001 a add fe80::1/64 dev lo
ip -n node001 a add fc00:1:1:: dev lo
ip -n node001 l set dev lo up
ip netns exec node001 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node001 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node001 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node001 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node001 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node002
ip -n node002 a add fe80::1/64 dev lo
ip -n node002 a add fc00:1:2:: dev lo
ip -n node002 l set dev lo up
ip netns exec node002 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node002 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node002 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node002 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node002 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node003
ip -n node003 a add fe80::1/64 dev lo
ip -n node003 a add fc00:1:3:: dev lo
ip -n node003 l set dev lo up
ip netns exec node003 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node003 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node003 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node003 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node003 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node004
ip -n node004 a add fe80::1/64 dev lo
ip -n node004 a add fc00:1:4:: dev lo
ip -n node004 l set dev lo up
ip netns exec node004 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node004 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node004 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node004 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node004 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node005
ip -n node005 a add fe80::1/64 dev lo
ip -n node005 a add fc00:1:5:: dev lo
ip -n node005 l set dev lo up
ip netns exec node005 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node005 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node005 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node005 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node005 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip -n node000 l add dev veth000000 type veth peer name veth001000
ip -n node000 l set dev veth001000 netns node001
ip -n node000 l set dev veth000000 up
ip -n node001 l set dev veth001000 up
ip -n node000 a add dev veth000000 10.0.0.0/31
ip -n node001 a add dev veth001000 10.0.0.1/31
ip -n node000 a add dev veth000000 fc01::/127
ip -n node001 a add dev veth001000 fc01::1/127
ip netns exec node000 bash -c "${ROOT}/delay.sh veth000000 15ms 1000mbit 15ms"
ip netns exec node001 bash -c "${ROOT}/delay.sh veth001000 15ms 1000mbit 15ms"
ip -n node000 l add dev veth000001 type veth peer name veth003000
ip -n node000 l set dev veth003000 netns node003
ip -n node000 l set dev veth000001 up
ip -n node003 l set dev veth003000 up
ip -n node000 a add dev veth000001 10.0.0.2/31
ip -n node003 a add dev veth003000 10.0.0.3/31
ip -n node000 a add dev veth000001 fc01::2/127
ip -n node003 a add dev veth003000 fc01::3/127
ip netns exec node000 bash -c "${ROOT}/delay.sh veth000001 15ms 1000mbit 15ms"
ip netns exec node003 bash -c "${ROOT}/delay.sh veth003000 15ms 1000mbit 15ms"
ip -n node001 l add dev veth001001 type veth peer name veth002000
ip -n node001 l set dev veth002000 netns node002
ip -n node001 l set dev veth001001 up
ip -n node002 l set dev veth002000 up
ip -n node001 a add dev veth001001 10.0.0.4/31
ip -n node002 a add dev veth002000 10.0.0.5/31
ip -n node001 a add dev veth001001 fc01::4/127
ip -n node002 a add dev veth002000 fc01::5/127
ip netns exec node001 bash -c "${ROOT}/delay.sh veth001001 15ms 1000mbit 15ms"
ip netns exec node002 bash -c "${ROOT}/delay.sh veth002000 15ms 1000mbit 15ms"
ip -n node002 l add dev veth002001 type veth peer name veth004000
ip -n node002 l set dev veth004000 netns node004
ip -n node002 l set dev veth002001 up
ip -n node004 l set dev veth004000 up
ip -n node002 a add dev veth002001 10.0.0.6/31
ip -n node004 a add dev veth004000 10.0.0.7/31
ip -n node002 a add dev veth002001 fc01::6/127
ip -n node004 a add dev veth004000 fc01::7/127
ip netns exec node002 bash -c "${ROOT}/delay.sh veth002001 15ms 1000mbit 15ms"
ip netns exec node004 bash -c "${ROOT}/delay.sh veth004000 15ms 1000mbit 15ms"
ip -n node003 l add dev veth003001 type veth peer name veth004001
ip -n node003 l set dev veth004001 netns node004
ip -n node003 l set dev veth003001 up
ip -n node004 l set dev veth004001 up
ip -n node003 a add dev veth003001 10.0.0.8/31
ip -n node004 a add dev veth004001 10.0.0.9/31
ip -n node003 a add dev veth003001 fc01::8/127
ip -n node004 a add dev veth004001 fc01::9/127
ip netns exec node003 bash -c "${ROOT}/delay.sh veth003001 15ms 1000mbit 15ms"
ip netns exec node004 bash -c "${ROOT}/delay.sh veth004001 15ms 1000mbit 15ms"
ip -n node003 l add dev veth003002 type veth peer name veth005000
ip -n node003 l set dev veth005000 netns node005
ip -n node003 l set dev veth003002 up
ip -n node005 l set dev veth005000 up
ip -n node003 a add dev veth003002 10.0.0.10/31
ip -n node005 a add dev veth005000 10.0.0.11/31
ip netns exec node005 bash -c "echo '10.0.0.11' > ${ROOT}/node005.gobgp.ipv4.nh"
ip -n node003 a add dev veth003002 fc01::a/127
ip -n node005 a add dev veth005000 fc01::b/127
ip netns exec node005 bash -c "echo 'fc01::b' > ${ROOT}/node005.gobgp.ipv6.nh"
ip netns exec node005 bash -c "echo veth005000 > ${ROOT}/node005.gobgp.iface"
ip netns exec node003 bash -c "${ROOT}/delay.sh veth003002 15ms 1000mbit 15ms"
ip netns exec node005 bash -c "${ROOT}/delay.sh veth005000 15ms 1000mbit 15ms"

function download_mrt() {
    # Snapshot from RRC20 Zurich 2023-04-02 4pm.
    # #IPv4 routes: 939 412
    # #IPv6 routes: 177 116
    curl -L https://data.ris.ripe.net/rrc20/2023.04/bview.20230402.1600.gz \
	 -o "$1" || (echo "curl failed" && exit 1)

    zcat "$1" > "$2"
    rm -f "$1"
}

MRT_DUMP=/tmp/rrc20_mrt.dump
MRT_DUMP_GZ=/tmp/rrc20_mrt.dump.gz

if [ ! -f $MRT_DUMP ]; then
    echo "[INFO] MRT Dump file not found! Downloading..."
    download_mrt "$MRT_DUMP_GZ" "$MRT_DUMP"
fi

