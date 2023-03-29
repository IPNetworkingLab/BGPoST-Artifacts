#!/usr/bin/env bash

if [ -z "${1}" ]; then
    echo "This script should take the node_id as argument"
    exit 1
fi

# exit when any command fails
set -e

# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\" command filed with exit code $?."' EXIT

GOBGP=/tmp/gobgp
GOBGPD=/tmp/gobgpd
MRT_DUMP=/root/mrt.dump

IPv4_NH=$(cat /tmp/"$1".gobgp.ipv4.nh)
IPv6_NH=$(cat /tmp/"$1".gobgp.ipv6.nh)

iface=$(cat /tmp/"$1".gobgp.iface)

if [ ! -f $GOBGP ]; then
  echo "[ERR] gobgp path not found !"
  exit 1
fi

if [ ! -f $GOBGPD ]; then
  echo "[ERR] gobgpd path not found !"
  exit 1
fi

if [ ! -f $MRT_DUMP ]; then
    echo "[ERR] MRT Dump file not found! Please run pre_download_mrt.sh before"
    exit 1
fi

# Keep all IPv6 addresses on an interface down event.
sysctl -w net.ipv6.conf.all.keep_addr_on_down=1

echo "[INFO] Setting ${iface} down while mrt is loaded"
ip link set dev "${iface}" down

# launch gobgpd on the node
$GOBGPD -f /tmp/"$1".gobgp.cfg &

# make sure gobgpd is launched and ready
sleep 1

if [[ -z $IPv4_NH ]]; then
  echo "[WARN] No IPv4 NextHop: Skipping IPv4 table advertisement"
else
  $GOBGP mrt inject global --only-best --nexthop "$IPv4_NH" --no-ipv6 $MRT_DUMP
fi

if [[ -z $IPv6_NH ]]; then
  echo "[WARN] No IPv6 NextHop: Skipping IPv6 table advertisement"
else
  $GOBGP mrt inject global --only-best --nexthop "$IPv6_NH" --no-ipv4 $MRT_DUMP
fi

echo "[INFO] MRT injection is finished, re-enabling ${iface}"
ip link set dev "${iface}" up