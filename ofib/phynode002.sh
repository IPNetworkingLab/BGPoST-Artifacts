#! /bin/bash -x

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi


export END_CPU=8
export ROOT=/root
export PYTHON_MINOR_VER=10
export FIRST_SETUP=${ROOT}/first_setup
export TMP=$(mktemp)
if [[ $# != 1 ]] && [[ ! -f $FIRST_SETUP ]]; then
DEBIAN_FRONTEND=noninteractive
sysctl -w net.ipv4.udp_rmem_min=4096000 \
          net.core.rmem_max=26214400 \
          net.core.rmem_default=26214400 \
          net.core.netdev_max_backlog=2000
apt-get update
apt-get autoremove -y
apt-get install software-properties-common curl libevent-dev cargo -y
#add-apt-repository -y ppa:deadsnakes/ppa
apt-get -y install python3."${PYTHON_MINOR_VER}" python3."${PYTHON_MINOR_VER}"-venv htop
python3."${PYTHON_MINOR_VER}" -m ensurepip --default-pip
python3."${PYTHON_MINOR_VER}" -m venv "${ROOT}"/env
source "${ROOT}"/env/bin/activate
pip install --upgrade pip
pip3 install jinja2 --log="${ROOT}/pip1.log"
pip3 install defusedxml --log="${ROOT}/pip2.log"
pip3 install tomli --log="${ROOT}/pip3.log"
pip3 install "${ROOT}"/netutils --log="${ROOT}"/netutils.install.log
#cat "${ROOT}"/roq_key.pub >> "${HOME}"/.ssh/authorized_keys
#mkdir -p /lib/modules/$(uname -r)/misc
#mv "${ROOT}"/vpoll.ko /lib/modules/$(uname -r)/misc
#depmod -a
#modprobe vpoll
#sed -i -e "s/GRUB_CMDLINE_LINUX_DEFAULT=\"\"/GRUB_CMDLINE_LINUX_DEFAULT=\"nosmt isolcpus=0-8\"/g" /etc/default/grub
#update-grub
#mv "${ROOT}"/roq /etc/init.d/
#update-rc.d roq defaults
touch "${FIRST_SETUP}"
#reboot
elif [[ $# != 1 ]] && [[ -f "${FIRST_SETUP}" ]]; then
ip netns add node018
ip -n node018 a add fe80::1/64 dev lo
ip -n node018 a add fc00:1:12:: dev lo
ip -n node018 l set dev lo up
ip netns exec node018 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node018 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node018 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node018 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node018 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node019
ip -n node019 a add fe80::1/64 dev lo
ip -n node019 a add fc00:1:13:: dev lo
ip -n node019 l set dev lo up
ip netns exec node019 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node019 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node019 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node019 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node019 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node020
ip -n node020 a add fe80::1/64 dev lo
ip -n node020 a add fc00:1:14:: dev lo
ip -n node020 l set dev lo up
ip netns exec node020 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node020 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node020 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node020 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node020 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node021
ip -n node021 a add fe80::1/64 dev lo
ip -n node021 a add fc00:1:15:: dev lo
ip -n node021 l set dev lo up
ip netns exec node021 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node021 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node021 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node021 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node021 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node022
ip -n node022 a add fe80::1/64 dev lo
ip -n node022 a add fc00:1:16:: dev lo
ip -n node022 l set dev lo up
ip netns exec node022 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node022 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node022 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node022 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node022 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node023
ip -n node023 a add fe80::1/64 dev lo
ip -n node023 a add fc00:1:17:: dev lo
ip -n node023 l set dev lo up
ip netns exec node023 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node023 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node023 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node023 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node023 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node024
ip -n node024 a add fe80::1/64 dev lo
ip -n node024 a add fc00:1:18:: dev lo
ip -n node024 l set dev lo up
ip netns exec node024 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node024 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node024 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node024 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node024 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node025
ip -n node025 a add fe80::1/64 dev lo
ip -n node025 a add fc00:1:19:: dev lo
ip -n node025 l set dev lo up
ip netns exec node025 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node025 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node025 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node025 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node025 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node026
ip -n node026 a add fe80::1/64 dev lo
ip -n node026 a add fc00:1:1a:: dev lo
ip -n node026 l set dev lo up
ip netns exec node026 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node026 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node026 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node026 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node026 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
./phynode002_vlans.sh
echo 025_000 | tee -a ${ROOT}/links
ip netns exec node025 bash -c "${ROOT}/delay.sh veth025000 10ms 1000mbit 10ms"
echo 024_000 | tee -a ${ROOT}/links
ip netns exec node024 bash -c "${ROOT}/delay.sh veth024000 10ms 1000mbit 10ms"
echo 023_000 | tee -a ${ROOT}/links
ip netns exec node023 bash -c "${ROOT}/delay.sh veth023000 10ms 1000mbit 10ms"
echo 018_000 | tee -a ${ROOT}/links
ip netns exec node018 bash -c "${ROOT}/delay.sh veth018000 10ms 1000mbit 10ms"
echo 018_001 | tee -a ${ROOT}/links
ip netns exec node018 bash -c "${ROOT}/delay.sh veth018001 10ms 1000mbit 10ms"
ip -n node019 l add dev veth019000 type veth peer name veth020000
ip -n node019 l set dev veth020000 netns node020
ip -n node019 l set dev veth019000 mtu 9000
ip -n node019 l set dev veth019000 up
ip -n node020 l set dev veth020000 mtu 9000
ip -n node020 l set dev veth020000 up
ip netns exec node019 bash -c "${ROOT}/delay.sh veth019000 10ms 1000mbit 10ms"
ip netns exec node020 bash -c "${ROOT}/delay.sh veth020000 10ms 1000mbit 10ms"
ip -n node019 l add dev veth019001 type veth peer name veth021000
ip -n node019 l set dev veth021000 netns node021
ip -n node019 l set dev veth019001 mtu 9000
ip -n node019 l set dev veth019001 up
ip -n node021 l set dev veth021000 mtu 9000
ip -n node021 l set dev veth021000 up
ip netns exec node019 bash -c "${ROOT}/delay.sh veth019001 10ms 1000mbit 10ms"
ip netns exec node021 bash -c "${ROOT}/delay.sh veth021000 10ms 1000mbit 10ms"
echo 020_001 | tee -a ${ROOT}/links
ip netns exec node020 bash -c "${ROOT}/delay.sh veth020001 10ms 1000mbit 10ms"
ip -n node021 l add dev veth021001 type veth peer name veth022000
ip -n node021 l set dev veth022000 netns node022
ip -n node021 l set dev veth021001 mtu 9000
ip -n node021 l set dev veth021001 up
ip -n node022 l set dev veth022000 mtu 9000
ip -n node022 l set dev veth022000 up
ip netns exec node021 bash -c "${ROOT}/delay.sh veth021001 10ms 1000mbit 10ms"
ip netns exec node022 bash -c "${ROOT}/delay.sh veth022000 10ms 1000mbit 10ms"
ip -n node022 l add dev veth022001 type veth peer name veth026000
ip -n node022 l set dev veth026000 netns node026
ip -n node022 l set dev veth022001 mtu 9000
ip -n node022 l set dev veth022001 up
ip -n node026 l set dev veth026000 mtu 9000
ip -n node026 l set dev veth026000 up
ip netns exec node022 bash -c "${ROOT}/delay.sh veth022001 10ms 1000mbit 10ms"
ip netns exec node026 bash -c "${ROOT}/delay.sh veth026000 10ms 1000mbit 10ms"
ip -n node023 l add dev veth023001 type veth peer name veth024001
ip -n node023 l set dev veth024001 netns node024
ip -n node023 l set dev veth023001 mtu 9000
ip -n node023 l set dev veth023001 up
ip -n node024 l set dev veth024001 mtu 9000
ip -n node024 l set dev veth024001 up
ip netns exec node023 bash -c "${ROOT}/delay.sh veth023001 10ms 1000mbit 10ms"
ip netns exec node024 bash -c "${ROOT}/delay.sh veth024001 10ms 1000mbit 10ms"
ip -n node025 l add dev veth025001 type veth peer name veth026001
ip -n node025 l set dev veth026001 netns node026
ip -n node025 l set dev veth025001 mtu 9000
ip -n node025 l set dev veth025001 up
ip -n node026 l set dev veth026001 mtu 9000
ip -n node026 l set dev veth026001 up
ip netns exec node025 bash -c "${ROOT}/delay.sh veth025001 10ms 1000mbit 10ms"
ip netns exec node026 bash -c "${ROOT}/delay.sh veth026001 10ms 1000mbit 10ms"
#"${ROOT}"/env/bin/python3 "${ROOT}"/setup.py ${ROOT}/links
ip netns exec node018 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node018 node018 0.0.0.0 ${TMP}"
ip netns exec node019 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node019 node019 0.0.0.0 ${TMP}"
ip netns exec node020 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node020 node020 0.0.0.0 ${TMP}"
ip netns exec node021 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node021 node021 0.0.0.0 ${TMP}"
ip netns exec node022 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node022 node022 0.0.0.0 ${TMP}"
ip netns exec node023 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node023 node023 0.0.0.0 ${TMP}"
ip netns exec node024 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node024 node024 0.0.0.0 ${TMP}"
ip netns exec node025 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node025 node025 0.0.0.0 ${TMP}"
ip netns exec node026 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node026 node026 0.0.0.0 ${TMP}"
#curl -X POST -H "Content-Type: application/json" -d "{\"topo\": \"579021709b636e877d429e38b593b2a421994116fa1fb246ee0f3112b530a9e3\", \"endpoint\": \"$(cat ${ROOT}/vnode)\"}" https://roq.info.ucl.ac.be:8080/e8b32bc4d7b564ac6075a1418ad8841e/endpoints
else
# core 0
IO_QUIC_CORE_ID=0 ip netns exec node018 bash -c "taskset -c 2 "${ROOT}"/bird -s /tmp/node018.bird.sk -c "${ROOT}"/node018.bird.cfg -P /tmp/node018.bird.pid &"
IO_QUIC_CORE_ID=4 ip netns exec node019 bash -c "taskset -c 6 "${ROOT}"/bird -s /tmp/node019.bird.sk -c "${ROOT}"/node019.bird.cfg -P /tmp/node019.bird.pid &"
IO_QUIC_CORE_ID=8 ip netns exec node020 bash -c "taskset -c 10 "${ROOT}"/bird -s /tmp/node020.bird.sk -c "${ROOT}"/node020.bird.cfg -P /tmp/node020.bird.pid &"
IO_QUIC_CORE_ID=12 ip netns exec node021 bash -c "taskset -c 14 "${ROOT}"/bird -s /tmp/node021.bird.sk -c "${ROOT}"/node021.bird.cfg -P /tmp/node021.bird.pid &"
IO_QUIC_CORE_ID=16 ip netns exec node022 bash -c "taskset -c 18 "${ROOT}"/bird -s /tmp/node022.bird.sk -c "${ROOT}"/node022.bird.cfg -P /tmp/node022.bird.pid &"
# core 1
IO_QUIC_CORE_ID=1 ip netns exec node023 bash -c "taskset -c 3 "${ROOT}"/bird -s /tmp/node023.bird.sk -c "${ROOT}"/node023.bird.cfg -P /tmp/node023.bird.pid &"
IO_QUIC_CORE_ID=5 ip netns exec node024 bash -c "taskset -c 7 "${ROOT}"/bird -s /tmp/node024.bird.sk -c "${ROOT}"/node024.bird.cfg -P /tmp/node024.bird.pid &"
IO_QUIC_CORE_ID=9 ip netns exec node025 bash -c "taskset -c 11 "${ROOT}"/bird -s /tmp/node025.bird.sk -c "${ROOT}"/node025.bird.cfg -P /tmp/node025.bird.pid &"
IO_QUIC_CORE_ID=13 ip netns exec node026 bash -c "taskset -c 15 "${ROOT}"/bird -s /tmp/node026.bird.sk -c "${ROOT}"/node026.bird.cfg -P /tmp/node026.bird.pid &"
fi
