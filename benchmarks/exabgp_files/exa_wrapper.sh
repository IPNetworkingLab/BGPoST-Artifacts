#!/bin/bash

### ExaBGP does not like programs with arguments....

/dev/shm/test_perf/exabgp/controlled_announce.py \
        --ipv6-nh fc01:: \
        --ipv4-nh 172.16.0.0 \
        -a 65000 \
        -p /dev/shm/test_perf/exabgp/prefixes.txt \
        -m 30000 # this should last 25 minutes to announce 30k routes