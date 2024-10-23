#!/bin/ash
#set -x

GOBGP="$(which gobgp || (echo "gobgp not found" && exit 1))"

if [ "${#}" != 4  ]; then
  echo "Usage: ${0} <iface> <nh_ipv4> <nh_ipv6> <mrtdump_file>"
  echo "           iface: Interface name that is connected to the BIRD router"
  echo "         nh_ipv4: IPv4 NextHop for BGP routes injected by GoBGP"
  echo "         nh_ipv6: IPv6 NextHop for BGP routes injected by GoBGP"
  echo "    mrtdump_file: MRT dump file containing routes to inject to the GoBGP RIB."
  exit 1
fi

TMP_DMP="/tmp/mrt.dump"

IFACE="${1}"
NH_IPV4="${2}"
NH_IPV6="${3}"
MRTDUMP="${4}"

if [[ "${MTDUMP}" == *.gz  ]]; then
    zcat "${MRTDUMP}" > "${TMP_DMP}"
    MRTDUMP="${TMP_DMP}"
fi

ip link set dev "${IFACE}" down

"${GOBGP}" mrt inject global --only-best --nexthop "${NH_IPV4}" --no-ipv6 "${MRTDUMP}"
"${GOBGP}" mrt inject global --only-best --nexthop "${NH_IPV6}" --no-ipv4 "${MRTDUMP}"

ip link set dev "${IFACE}" up

if [ -f "${TMP_DMP}"  ]; then
  rm -f "${TMP_DMP}"
fi

