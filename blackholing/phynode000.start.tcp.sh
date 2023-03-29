#! /bin/bash -x

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

export ROOT=/tmp

ip netns exec node000 bash -c "taskset -c 0 "${ROOT}"/bird -s /tmp/node000.bird.sk -c "${ROOT}"/tcp_exp/node000.bird.cfg -P /tmp/node000.bird.pid &"
ip netns exec node001 bash -c "taskset -c 1 "${ROOT}"/bird -s /tmp/node001.bird.sk -c "${ROOT}"/tcp_exp/node001.bird.cfg -P /tmp/node001.bird.pid &"
ip netns exec node002 bash -c "taskset -c 2 "${ROOT}"/bird -s /tmp/node002.bird.sk -c "${ROOT}"/tcp_exp/node002.bird.cfg -P /tmp/node002.bird.pid &"
ip netns exec node003 bash -c "taskset -c 3 "${ROOT}"/bird -s /tmp/node003.bird.sk -c "${ROOT}"/tcp_exp/node003.bird.cfg -P /tmp/node003.bird.pid &"
ip netns exec node004 bash -c "taskset -c 4 "${ROOT}"/bird -s /tmp/node004.bird.sk -c "${ROOT}"/tcp_exp/node004.bird.cfg -P /tmp/node004.bird.pid &"
ip netns exec node005 bash -c "taskset -c 5 "${ROOT}"/bird -s /tmp/node005.bird.sk -c "${ROOT}"/tcp_exp/node005.bird.cfg -P /tmp/node005.bird.pid &"
