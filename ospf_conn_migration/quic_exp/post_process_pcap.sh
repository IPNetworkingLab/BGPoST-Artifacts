#!/bin/bash

if [ $# -ne 3 ]; then
  echo "Usage: $0 <NB_EXPS> <IN_DIR> <OUT_DIR>"
  exit 1
fi

NB_EXPS="$1"
IN_DIR="$2"
OUT_DIR="$3"

for i in $(seq 1 "${NB_EXPS}"); do
  echo "Processing ${IN_DIR}/node1.${i}.pcapng"

  tshark -T json -e udp.length \
	  -e frame.time_relative \
	  -r "${IN_DIR}/node1.${i}.pcapng" \
	 udp > "${OUT_DIR}/node1.${i}.json"

done
