#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

if [ $# -ne 2 ]; then
  echo "Usage $0 <max_exps> <result_dir>"
fi

MAX_EXP=$1
RESULT_DIR=$2

mkdir -p "$RESULT_DIR"

for i in $(seq 1 "${MAX_EXP}"); do
  echo "Experiment ${i}/${MAX_EXP}"

  #1. launch all bird instances
  bash phynode000.start.quic.sh && sleep 10

  #2. trigger RTBH from node000 to node004
  ./birdc -s /tmp/node000.bird.sk << EOF
  configure soft "/tmp/quic_exp/node000.bird.cfg.rtbh"
  quit
EOF

  sleep 6 && pkill bird && sleep 2

  #3. Move dumps to another location.
  mv /tmp/node001.updates.mrt "${RESULT_DIR}"/node001.updates.mrt."${i}"
  mv /tmp/node005.updates.mrt "${RESULT_DIR}"/node005.updates.mrt."${i}"
done
