#! /bin/bash -xe

git submodule update --init --recursive
docker build -t bgptls -f BGPoTLS/Dockerfile BGPoTLS
docker build -t gobgp -f Dockerfile.gobgp .
sudo containerlab deploy -t bgptls.clab.yml --reconfigure
