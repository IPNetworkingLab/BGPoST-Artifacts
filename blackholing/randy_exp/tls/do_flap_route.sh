#!/bin/bash

if [ "$#" -ne "2" ]; then
  echo "usage: $0 <birdc path> <bird control socket path>"
  exit 1
fi

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BIRDC="$1"
BIRD_SK="$2"
FLAP_ROUTE="${__dir}/../flap_route.py"

FLAP_NB=14400

for i in $(seq 1 $FLAP_NB); do
  echo "Flap ${i}/${FLAP_NB}"
  ${FLAP_ROUTE} -b "${BIRDC}" -s "${BIRD_SK}" -p static1
  sleep 1
done
