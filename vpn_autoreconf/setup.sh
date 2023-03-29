#!/bin/bash

# configure simple BGP/VPN MPLS network
#                                      10.40.41.0/24
#                                  (in router links)
# +-------------------+         +--------------------+
# |    192.0.2.0/24   |         |  VPN Provider      |
# | +---+.2       .1+---+.5     | .4+---+            |
# | |PC1+-----------+CE1+-------+---+PE1|            |
# | +---+           +---+       |   +-+-+            |
# +-------------------+         |     | .2           |
#                               |     |              |
# +-------------------+         |     | .3           |
# | +---+.2       .1+---+.7     | .6+-+-+            |
# | |PC2+-----------+CE2+-------+---+PE2|            |
# | +---+           +---+       |   +---+            |
# |  198.51.100.0/24  |         |                    |
# +-------------------+         +--------------------+

function usage() {
  echo "$0 <bird_exec_path> {start|stop|destroy|reload}"
  echo "   <bird_exec_path>: path to the bird executable"
  echo "   start: run the mini network"
  echo "   stop: stop the mini network (shutdown routing processes)"
  echo "   destroy: delete all ns, folders, states & processes created by this script"
  echo "   reload: do graceful restart on CE1 router, to change certificate"
  exit 1
}

export PYTHONUNBUFFERED="true"

if (( $EUID != 0 )); then
  echo "Please run as root"
  exit 1
fi

if [ -z "${VIRTUAL_ENV}" ]; then
  echo "Please run this script in a virtual environment"
  exit 1
fi

if [ "$#" -ne "2" ]; then
  usage
fi

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIRD="$1"
VARDIR="/dev/shm/autovpn_exp"

function setup_ns() {
  # load mpls modules (if not loaded yet)
  modprobe mpls_router
  modprobe mpls_iptunnel
	
  ip netns add ce1
  ip netns add ce2
  ip netns add pe1
  ip netns add pe2
  ip netns add pc1
  ip netns add pc2

  ip link add eth1 netns ce1 type veth peer eth1 netns pe1
  ip link add eth1 netns ce2 type veth peer eth1 netns pe2
  ip link add eth2 netns pe1 type veth peer eth2 netns pe2
  ip link add lan1 netns ce1 type veth peer lan1 netns pc1
  ip link add lan1 netns ce2 type veth peer lan1 netns pc2

  # setup vrf interfaces
  for ns in pe1 pe2; do
    ip -n ${ns} link add blue type vrf table 10
    ip -n ${ns} link set eth1 master blue
    ip -n ${ns} link set dev blue up

    # setup mpls sysctl !!
    ip netns exec ${ns} sysctl net.mpls.conf.eth1.input=1
    ip netns exec ${ns} sysctl net.mpls.conf.eth2.input=1
    ip netns exec ${ns} sysctl net.mpls.platform_labels=20000
  done

  ip -n ce1 link set dev lo up
  ip -n ce2 link set dev lo up
  ip -n pe1 link set dev lo up
  ip -n pe2 link set dev lo up
  ip -n pc1 link set dev lo up
  ip -n pc2 link set dev lo up

  # add VPN addresses on PC1 PC2
  ip -n pc1 addr add 192.0.2.2/24 dev lan1
  ip -n pc2 addr add 198.51.100.2/24 dev lan1
  ip -n ce1 addr add 192.0.2.1/24 dev lan1
  ip -n ce2 addr add 198.51.100.1/24 dev lan1

  ip -n ce1 addr add 10.40.41.5/31 dev eth1
  ip -n ce2 addr add 10.40.41.7/31 dev eth1

  ip -n pe1 addr add 10.40.41.2/31 dev eth2
  ip -n pe2 addr add 10.40.41.3/31 dev eth2

  ip -n pe1 addr add 10.40.41.4/31 dev eth1
  ip -n pe2 addr add 10.40.41.6/31 dev eth1

  ip -n ce1 link set dev eth1 up
  ip -n ce2 link set dev eth1 up
  ip -n pe1 link set dev eth1 up
  ip -n pe1 link set dev eth2 up
  ip -n pe2 link set dev eth1 up
  ip -n pe2 link set dev eth2 up
  ip -n ce1 link set dev lan1 up
  ip -n ce2 link set dev lan1 up
  ip -n pc1 link set dev lan1 up
  ip -n pc2 link set dev lan1 up

  # setup Max BW & delay on links CE1 - PE1 & CE2 - PE2
  # 200Mbps 1ms latency
  for ns in ce1 ce2 pe1 pe2; do
    ip netns exec "${ns}" "${__dir}"/setup_delay.sh eth1 15ms 200Mbit 25ms
  done

  # add default route on PC1 PC2
  ip -n pc1 route add default via 192.0.2.1
  ip -n pc2 route add default via 198.51.100.1

  # generate certificates (and clean up old ones to regenerate them)
  "${__dir}"/certs/generate_local_certs.sh clean

  mkdir -p "${VARDIR}"
  # add root CA to top root VARDIR directory
  cp "${__dir}"/certs/ca.cert.pem "${VARDIR}"

  for ns in ce1 ce2 pe1 pe2; do
    # configure ipv4 forward
    ip netns exec ${ns} sysctl net.ipv4.ip_forward=1
    mkdir -p ${VARDIR}/${ns}
    cp "${__dir}"/cfgs/${ns}*.conf ${VARDIR}/${ns}
    cp "${__dir}"/certs/${ns}*.key certs/${ns}*.cert.pem ${VARDIR}/${ns}
  done

}

function start_iperf() {
  # collect throughput values

  # start tcpdump
  ip netns exec pe1 tshark -n -i eth1 -s 96 -w ${VARDIR}/pe1.pcapng &
  echo "$!" > "${VARDIR}/pe1.tcpdump.pid"

  # then iperf
  ip netns exec pc2 iperf3 -s -p 5201 > /dev/null 2>&1 &
  echo "$!" > "${VARDIR}/pc2.iperf3.pid"
  ip netns exec pc1 "${__dir}/iperf_client.sh" 198.51.100.2 5201 "${VARDIR}/pc1.iperf3.pid" > /dev/null 2>&1 &
}

function stop_iperf() {
  kill "$(cat ${VARDIR}/pe1.tcpdump.pid)"
  rm -f "${VARDIR}/pe1.tcpdump.pid"
  # first stop PC1, the client
  kill "$(cat ${VARDIR}/pc1.iperf3.pid)"
  rm -f "${VARDIR}/pc1.iperf3.pid"
  # then stop PC2 the server
  kill "$(cat ${VARDIR}/pc2.iperf3.pid)"
  rm -f "${VARDIR}/pc2.iperf3.pid"

  chmod go+r "${VARDIR}/pe1.pcapng"
}

function run_bird() {
  local ctrl_serv="${__dir}"/../bgp_multihomed/autoreconf_tls/control_server.py
  for ns in ce1 ce2 pe1 pe2; do
    local sk_file=${VARDIR}/${ns}/${ns}.ctrl_serv.sk
    # make sure ctrl socket is deleted
    rm -f ${sk_file}
    # run control server (apply config from the certificates)
    PYTHONPATH="${__dir}/.." ip netns exec ${ns} "${ctrl_serv}" -s ${sk_file}  > \
        "${VARDIR}/${ns}/${ns}.ctrl_serv.log" 2>&1 &
    echo "$!" > ${VARDIR}/${ns}/${ns}.ctrl_serv.pid
    
    # wait that socket is created in FS
    while [ ! -S ${sk_file} ]; do sleep 1; done

    ip netns exec ${ns} "${BIRD}" -c ${VARDIR}/${ns}/${ns}.conf \
                      -s ${VARDIR}/${ns}/${ns}.sk \
                      -P ${VARDIR}/${ns}/${ns}.pid
  done
}

function run_simple_bird() {
  for ns in ce1 ce2 pe1 pe2; do
    ip netns exec ${ns} "${BIRD}" -c ${VARDIR}/${ns}/${ns}.tcp.conf \
                      -s ${VARDIR}/${ns}/${ns}.sk \
                      -P ${VARDIR}/${ns}/${ns}.pid
  done
}

function stop_bird() {
  stop_iperf

  for ns in ce1 ce2 pe1 pe2; do
    kill "$(cat ${VARDIR}/${ns}/${ns}.ctrl_serv.pid)"
    kill "$(cat ${VARDIR}/${ns}/${ns}.pid)"
  done
}

function do_gr() {
  # XXX this assume bird and birdc in the same directory
  ${BIRD}c -s ${VARDIR}/ce1/ce1.sk << EOF
graceful restart
EOF

 # Ok now, we can restart CE1 with 50Mbps certificate
 # Note the -R option to tell GR start
 ip netns exec ce1 "${BIRD}" -Rc ${VARDIR}/ce1/ce1.50m.conf \
                             -s ${VARDIR}/ce1/ce1.sk \
                             -P ${VARDIR}/ce1/ce1.pid
 echo "Restarted"
}

function do_gr_tcp() {
  "${BIRD}c" -s "${VARDIR}/ce1/ce1.sk" << EOF
graceful restart
EOF

  ip netns exec ce1 "${BIRD}" -Rc ${VARDIR}/ce1/ce1.tcp.conf \
                              -s ${VARDIR}/ce1/ce1.sk \
                              -P ${VARDIR}/ce1/ce1.pid

  echo "Restarted"
}

function check_ns() {
  if ip netns exec ce1 true > /dev/null 2>&1; then
    return 0;
  else
    return 1;
  fi
}

function destroy() {
  stop_bird
  rm -rf ${VARDIR}
  for ns in ce1 ce2 pe1 pe2 pc1 pc2; do
    ip netns del ${ns}
  done
}

#### ENTRY POINT ####

case "$2" in
  "start")
    if ! check_ns; then
      setup_ns
    fi
    start_iperf
    run_bird
    ;;
  "start-tcp")
    if ! check_ns; then
      setup_ns
    fi
    run_simple_bird
    ;;
  "stop")
    stop_bird
    ;;
  "destroy")
    destroy
    ;;
  "reload")
    do_gr
    ;;
  "reload-tcp")
    do_gr_tcp
    ;;
  *)
    usage
    ;;
esac

