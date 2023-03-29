#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root";
  exit 1;
fi

if [ $# -ne 2 ]; then
  echo "Usage $0 <NB RUNS> <Result DIR>";
  exit 1;
fi

NB_EXPS=$1
RUN_DIR=$2

mkdir -p "$RUN_DIR"

echo "Start TCP experiments"
bash phynode000.measure.tcp.sh  "$NB_EXPS" "$RUN_DIR"/tcp
echo "Start QUIC experiments"
bash phynode000.measure.quic.sh "$NB_EXPS" "$RUN_DIR"/quic

