#!/bin/bash

git clone https://github.com/Tantalor93/dnspyre.git dnspyre

pushd ./dnspyre || exit 1

git checkout v2.21.3
go build

popd || exit 1