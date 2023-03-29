#!/bin/bash

if [[ "$#" -ne "3" &&  "$#" -ne "4" ]];  then
  echo "$0 <IP> <PORT> <PID_FILE> {iperf BW}"
  exit 1
fi

TARGET_IP="$1"
TARGET_PORT="$2"
PID_FILE="$3"
BANDWIDTH=0

if [ -n "${4+x}" ]; then
  BANDWIDTH="${4}"
fi

# wait connectivity
until ping -c1 "$1" >/dev/null 2>&1; do :; done &    # The "&" backgrounds it
trap "kill $!; ping_cancelled=true" SIGINT
wait $!          # Wait for the loop to exit, one way or another
trap - SIGINT    # Remove the trap, now we're done with it
echo "Done pinging, cancelled=$ping_cancelled"

# now do the iperf3 (UDP mode)
iperf3 -Z -tinf -c "${TARGET_IP}" -p "${TARGET_PORT}" -u -b "${BANDWIDTH}" -R > /dev/null 2>&1 &
echo "$!" > "${PID_FILE}"
