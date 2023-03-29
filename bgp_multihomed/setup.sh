#!/bin/bash
#                            Monitor RTR
#                  +------+    +------+
# Static +---------+AS2-R1+----+AS3-R1|
# Route  |         +--+---+    +------+
#        |            | BGP Session
#     +--+---+     +--+---+
#     |AS1-R2+-----+AS1-R1|
#     +------+     +------+
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ulimit -c unlimited

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

function usage() {
  echo "$0 <bird_path> <cmd>"
  echo "  <cmd>: can be any of the following directives:"
  echo "        setup: setup the namespaces and runtime dir"
  echo "        start: launch bird"
  echo "      destroy: remove everything created by this script"
  echo "         stop: kill all bird instances created by this script"
  echo "      reroute: force traffic and BGP to communicate through GRE tunnel"
  echo " <bird_path>: path to the BIRD executable"

  exit 1
}

if [ "$#" -ne 2 ]; then
  usage
fi

BIRD="$1"
VARDIR="/dev/shm/multihomed_exp"


function get_mac() {
  ip -n "$1" link show "$2" | awk '{print $2}' | xargs -n 2 | awk '{print $2}'
}

function set_sysctls() {
  local ns="${1}"
  ip netns exec "${ns}" sysctl net.ipv4.conf.default.ignore_routes_with_linkdown=1
  ip netns exec "${ns}" sysctl net.ipv4.conf.all.ignore_routes_with_linkdown=1
  ip netns exec "${ns}" sysctl net.ipv4.udp_rmem_min=4096000
  ip netns exec "${ns}" sysctl net.ipv4.udp_wmem_min=4096000
}

function did_you_increase_udp_buffers() {
  sysctl net.ipv4.udp_rmem_min=4096000
  sysctl net.ipv4.udp_wmem_min=4096000
  sysctl net.core.rmem_max=26214400
  sysctl net.core.wmem_max=26214400
  sysctl net.core.rmem_default=26214400
  sysctl net.core.wmem_default=26214400
  sysctl net.core.netdev_max_backlog=2000
}


function setup_ns() {

  if [ -n "$CERT_GENERATOR" ]; then
    echo "Missing path to the cert generator script (last argument/3rd of this script)"
    exit 1
  fi

  # add netns
  ip netns add as1-r1
  ip netns add as1-r2
  ip netns add as2-r1
  ip netns add as3-r1
  # netns for control PC in AS1
  ip netns add as1-pc1

  # add eth pair between netns
  ip link add eth-as2r1 netns as1-r1 type veth peer eth-as1r1 netns as2-r1
  ip link add eth-as1r2 netns as1-r1 type veth peer eth-as1r1 netns as1-r2
  ip link add eth-as2r1 netns as1-r2 type veth peer eth-as1r2 netns as2-r1
  ip link add eth-as3r1 netns as2-r1 type veth peer eth-as2r1 netns as3-r1
  ip link add eth-pc1 netns as1-r1 type veth peer eth-as1r1 netns as1-pc1

  ip -n as1-r1 link set dev lo up
  ip -n as1-r2 link set dev lo up
  ip -n as2-r1 link set dev lo up
  ip -n as3-r1 link set dev lo up
  ip -n as1-pc1 link set dev lo up

  # assign IPs
  ip -n as1-r1 addr add 10.0.1.1/24 dev eth-as2r1
  ip -n as2-r1 addr add 10.0.1.2/24 dev eth-as1r1

  ip -n as1-r1 addr add 10.0.0.1/24 dev eth-as1r2
  ip -n as1-r2 addr add 10.0.0.2/24 dev eth-as1r1

  ip -n as1-r1 neigh add 10.0.0.2 lladdr "$(get_mac as1-r2 eth-as1r1)" nud permanent dev eth-as2r1
  ip -n as1-r2 neigh add 10.0.0.1 lladdr "$(get_mac as1-r1 eth-as1r2)" nud permanent dev eth-as1r1

  ip -n as1-r2 addr add 10.0.2.1/24 dev eth-as2r1
  ip -n as2-r1 addr add 10.0.2.2/24 dev eth-as1r2

  ip -n as1-r2 neigh add 10.0.2.2 lladdr "$(get_mac as2-r1 eth-as1r2)" nud permanent dev eth-as2r1
  ip -n as2-r1 neigh add 10.0.2.1 lladdr "$(get_mac as1-r2 eth-as2r1)" nud permanent dev eth-as1r2

  ip -n as2-r1 addr add 10.0.3.2/24 dev eth-as3r1
  ip -n as3-r1 addr add 10.0.3.1/24 dev eth-as2r1

  ip -n as1-pc1 addr add 42.42.42.42/24 dev eth-as1r1
  ip -n as1-r1 addr add 42.42.42.1/24 dev eth-pc1


  # bring interfaces UP
  ip -n as1-r1 link set dev eth-as2r1 up
  ip -n as1-r1 link set dev eth-as1r2 up
  ip -n as1-r2 link set dev eth-as1r1 up
  ip -n as1-r2 link set dev eth-as2r1 up
  ip -n as2-r1 link set dev eth-as1r1 up
  ip -n as2-r1 link set dev eth-as1r2 up
  ip -n as2-r1 link set dev eth-as3r1 up
  ip -n as3-r1 link set dev eth-as2r1 up
  ip -n as1-r1 link set dev eth-pc1 up
  ip -n as1-pc1 link set dev eth-as1r1 up

  # default route for PC1
  ip -n as1-pc1 route add default via 42.42.42.1 src 42.42.42.42

  # add delays on links (10M, 30ms RTT) 10M to limit iperf trace
  ip netns exec as1-r1 ./setup_delay.sh eth-as1r2 15ms 10Mbit 25ms
  ip netns exec as1-r1 ./setup_delay.sh eth-as2r1 15ms 10Mbit 25ms

  ip netns exec as1-r2 ./setup_delay.sh eth-as1r1 15ms 10Mbit 25ms
  ip netns exec as1-r2 ./setup_delay.sh eth-as2r1 15ms 10Mbit 25ms

  ip netns exec as2-r1 ./setup_delay.sh eth-as1r1 15ms 10Mbit 25ms
  ip netns exec as2-r1 ./setup_delay.sh eth-as1r2 15ms 10Mbit 25ms
  ip netns exec as2-r1 ./setup_delay.sh eth-as3r1 15ms 10Mbit 25ms

  ip netns exec as3-r1 ./setup_delay.sh eth-as2r1 15ms 10Mbit 25ms

  ip netns exec as1-r1 ./setup_delay.sh eth-pc1 15ms 10Mbit 25ms
  ip netns exec as1-pc1 ./setup_delay.sh eth-as1r1 15ms 10Mbit 25ms

  # change MTU on endpoints to adapt to the mtu of the GRE tunnel
  ip -n as1-pc1 link set dev eth-as1r1 mtu 1450
  ip -n as1-r1 link set dev eth-pc1 mtu 1450
  ip -n as3-r1 link set dev eth-as2r1 mtu 1450
  ip -n as2-r1 link set dev eth-as3r1 mtu 1450

  # IP forward for as1-r2 node
  for ns in as1-r1 as1-r2 as2-r1 as3-r1; do
    ip netns exec "${ns}" sysctl net.ipv4.ip_forward=1
    set_sysctls "${ns}"
  done

  # increase UDP buffers for end-nodes as
  set_sysctls as1-pc1

  # add static route
  #ip -n as2-r1 route add 10.0.0.0/24 via 10.0.2.1
  #ip -n as1-r1 route add 10.0.2.0/24 via 10.0.0.2

  # prebuild tunnel
  #ip -n as1-r1 tunnel add gre-as2 mode gre remote 10.0.2.2 local 10.0.0.1
  #ip -n as1-r1 addr add 172.16.61.1/24 dev gre-as2
  #ip -n as2-r1 tunnel add gre-as1 mode gre remote 10.0.0.1 local 10.0.2.2
  #ip -n as2-r1 addr add 172.16.61.2/24 dev gre-as1
  #ip -n as1-r1 link set dev gre-as2 up
  #ip -n as2-r1 link set dev gre-as1 up

  # loopback eBGP (ah yes, the good practices...)
  ip -n as1-r1 addr add 192.168.68.1/32 dev lo
  ip -n as2-r1 addr add 192.168.68.2/32 dev lo

  # direct route to loopback
  #ip -n as1-r1 route add 192.168.68.2/32 via 10.0.1.2 metric 100
  #ip -n as2-r1 route add 192.168.68.1/32 via 10.0.1.1 metric 100

  # alternative route via tunnel to loopback
  #ip -n as1-r1 route add 192.168.68.2/32 via 172.16.61.2 dev gre-as2 metric 600
  #ip -n as2-r1 route add 192.168.68.1/32 via 172.16.61.1 dev gre-as1 metric 600


  ## build runtime dir
  mkdir -p "${VARDIR}"

  # generate certificate config
  "${__dir}/cfgs/certs/generate_certs.sh"

  for ns in as1-r1 as2-r1 as3-r1; do
    mkdir "${VARDIR}"/"$ns"
  done

  # copy root ca
  cp "${__dir}/cfgs/certs/ca.cert.pem" "${VARDIR}"

  # copy certs/key on the right folder
  for ns in as1-r1 as2-r1; do
    cp "${__dir}/cfgs/certs/${ns}.cert.pem" ${VARDIR}/${ns}
    cp "${__dir}/cfgs/certs/${ns}.key" ${VARDIR}/${ns}
  done

}

function start_bird() {
  local ctrl_serv="${__dir}"/autoreconf_tls/control_server.py

  # make sure interface is up
  ip -n as1-r1 link set dev eth-as2r1 up


  #ip netns exec $ns tcpdump -Uni any -s 96 -w "${VARDIR}"/as2-r1/trace.pcap &
  ip netns exec as2-r1 tshark -n -i eth-as1r2 -i eth-as1r1 -s 96 -w "${VARDIR}"/as2-r1/trace.pcapng &
  echo "$!" > "${VARDIR}"/as2-r1/tcpdump.pid
  sleep 5

  ## start netlink collector
  "${__dir}/netlink_collector.py" -o "${VARDIR}/netlink.yml" as1-r1 as2-r2 as2-r1 &
  echo "$!" > "${VARDIR}/netlink.pid"

  for ns in as1-r1 as2-r1; do
    local ctrl_sk=${VARDIR}/${ns}/${ns}.ctrl_serv.sk
    # run control server
    PYTHONPATH="${__dir}/.." ip netns exec "${ns}" nohup "${ctrl_serv}" -s "${ctrl_sk}" 2>&1 &
    echo "$!" > ${VARDIR}/${ns}/${ns}.ctrl_serv.pid

    # wait that socket is created in FS
    while [ ! -S ${ctrl_sk} ]; do sleep 1; done

    ip netns exec "${ns}" "$BIRD" -fc "${__dir}"/cfgs/"${ns}".conf \
              -s ${VARDIR}/"${ns}"/bird.sk \
              -P ${VARDIR}/"${ns}"/bird.pid > "${VARDIR}/${ns}/bird.std" 2>&1 &
  done

  # manually launch as3-r1 (BGP-TLS not activated)
  ip netns exec as3-r1 "$BIRD" -fc "${__dir}"/cfgs/as3-r1.conf \
              -s ${VARDIR}/as3-r1/bird.sk \
              -P ${VARDIR}/as3-r1/bird.pid &

  ## launch iperf server on as3-r1
  ip netns exec as3-r1 iperf3 -s -p 5201 &
  echo "$!" > "${VARDIR}/as3-r1/iperf3.pid"
  ## launch iperf client on as1-pc1 (Target rate of 9Mbits)
  ip netns exec as1-pc1 "${__dir}/../vpn_autoreconf/iperf_client.sh" 10.0.3.1 5201 "${VARDIR}/iperf.as1_pc1.pid" "9M" &
}

function stop_bird {

  # stop netlink collector
  kill -INT "$(cat "${VARDIR}/netlink.pid")"
  rm -f "${VARDIR}/netlink.pid"

  for ns in as1-r1 as2-r1 as3-r1; do
    kill "$(cat "${VARDIR}"/"$ns"/bird.pid)"
    kill "$(cat ${VARDIR}/${ns}/${ns}.ctrl_serv.pid)"
  done

  # stop iperf
  kill "$(cat ${VARDIR}/as3-r1/iperf3.pid)"
  kill "$(cat ${VARDIR}/iperf.as1_pc1.pid)"

  # also, stop tcpdump
  kill "$(cat "${VARDIR}"/as2-r1/tcpdump.pid)"
  chmod go+r "${VARDIR}/as2-r1/trace.pcapng"
}

function destroy {
  stop_bird

  for ns in as1-r1 as1-r2 as2-r1 as3-r1 as1-pc1; do
    ip netns del "$ns"
  done

  rm -rf "${VARDIR}"
}

function reroute() {
    # make sure to route BGP through GRE tunnel
    echo "$(date +%s%N): Putting down main link!" | tee "${VARDIR}/down_time.txt"
    ip -n as1-r1 link set dev eth-as2r1 down

### This should be handled by sysctl config
#     # delete route to main link
#     for ns in as1-r1 as2-r1; do
#       "${BIRD}c" -s ${VARDIR}/${ns}/bird.sk <<EOF
# configure soft "${__dir}/cfgs/${ns}.reroute.conf"
# EOF
#     done

}

function check_ns() {
  if ip netns exec as1-r1 true > /dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

#### MAIN ####

if ! check_ns; then
  setup_ns
fi

case "$2" in
  "setup")
    # setup done before so just quit the script
    ;;
  "start")
    start_bird
    ;;
  "reroute")
    reroute
    ;;
  "stop")
    stop_bird
    ;;
  "destroy")
    destroy
    ;;
  *)
    usage
    ;;
esac
