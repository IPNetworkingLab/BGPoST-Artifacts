#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "This script should take the workdir as argument"
fi

WORK_DIR="${1}"

if test -f "${WORK_DIR}"/mrt.dump; then
  # dump is already present
  exit 0
fi

curl -L "https://data.ris.ripe.net/rrc01/2023.11/bview.20231115.0000.gz" -o - | \
   zcat > "$WORK_DIR"/mrt.dump