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
ip netns add node027
ip -n node027 a add fe80::1/64 dev lo
ip -n node027 a add fc00:1:1b:: dev lo
ip -n node027 l set dev lo up
ip netns exec node027 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node027 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node027 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node027 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node027 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node028
ip -n node028 a add fe80::1/64 dev lo
ip -n node028 a add fc00:1:1c:: dev lo
ip -n node028 l set dev lo up
ip netns exec node028 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node028 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node028 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node028 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node028 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node029
ip -n node029 a add fe80::1/64 dev lo
ip -n node029 a add fc00:1:1d:: dev lo
ip -n node029 l set dev lo up
ip netns exec node029 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node029 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node029 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node029 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node029 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node030
ip -n node030 a add fe80::1/64 dev lo
ip -n node030 a add fc00:1:1e:: dev lo
ip -n node030 l set dev lo up
ip netns exec node030 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node030 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node030 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node030 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node030 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node031
ip -n node031 a add fe80::1/64 dev lo
ip -n node031 a add fc00:1:1f:: dev lo
ip -n node031 l set dev lo up
ip netns exec node031 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node031 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node031 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node031 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node031 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node032
ip -n node032 a add fe80::1/64 dev lo
ip -n node032 a add fc00:1:20:: dev lo
ip -n node032 l set dev lo up
ip netns exec node032 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node032 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node032 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node032 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node032 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node033
ip -n node033 a add fe80::1/64 dev lo
ip -n node033 a add fc00:1:21:: dev lo
ip -n node033 l set dev lo up
ip netns exec node033 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node033 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node033 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node033 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node033 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node034
ip -n node034 a add fe80::1/64 dev lo
ip -n node034 a add fc00:1:22:: dev lo
ip -n node034 l set dev lo up
ip netns exec node034 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node034 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node034 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node034 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node034 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node035
ip -n node035 a add fe80::1/64 dev lo
ip -n node035 a add fc00:1:23:: dev lo
ip -n node035 l set dev lo up
ip netns exec node035 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node035 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node035 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node035 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node035 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
./phynode003_vlans.sh
echo 027_000 | tee -a ${ROOT}/links
ip netns exec node027 bash -c "${ROOT}/delay.sh veth027000 10ms 1000mbit 10ms"
echo 030_000 | tee -a ${ROOT}/links
ip netns exec node030 bash -c "${ROOT}/delay.sh veth030000 10ms 1000mbit 10ms"
echo 031_000 | tee -a ${ROOT}/links
ip netns exec node031 bash -c "${ROOT}/delay.sh veth031000 10ms 1000mbit 10ms"
echo 032_000 | tee -a ${ROOT}/links
ip netns exec node032 bash -c "${ROOT}/delay.sh veth032000 10ms 1000mbit 10ms"
echo 033_000 | tee -a ${ROOT}/links
ip netns exec node033 bash -c "${ROOT}/delay.sh veth033000 10ms 1000mbit 10ms"
echo 028_000 | tee -a ${ROOT}/links
ip netns exec node028 bash -c "${ROOT}/delay.sh veth028000 10ms 1000mbit 10ms"
echo 029_000 | tee -a ${ROOT}/links
ip netns exec node029 bash -c "${ROOT}/delay.sh veth029000 10ms 1000mbit 10ms"
echo 034_000 | tee -a ${ROOT}/links
ip netns exec node034 bash -c "${ROOT}/delay.sh veth034000 10ms 1000mbit 10ms"
echo 029_001 | tee -a ${ROOT}/links
ip netns exec node029 bash -c "${ROOT}/delay.sh veth029001 10ms 1000mbit 10ms"
echo 027_001 | tee -a ${ROOT}/links
ip netns exec node027 bash -c "${ROOT}/delay.sh veth027001 10ms 1000mbit 10ms"
ip -n node027 l add dev veth027002 type veth peer name veth035000
ip -n node027 l set dev veth035000 netns node035
ip -n node027 l set dev veth027002 mtu 9000
ip -n node027 l set dev veth027002 up
ip -n node035 l set dev veth035000 mtu 9000
ip -n node035 l set dev veth035000 up
ip netns exec node027 bash -c "${ROOT}/delay.sh veth027002 10ms 1000mbit 10ms"
ip netns exec node035 bash -c "${ROOT}/delay.sh veth035000 10ms 1000mbit 10ms"
ip -n node030 l add dev veth030001 type veth peer name veth034001
ip -n node030 l set dev veth034001 netns node034
ip -n node030 l set dev veth030001 mtu 9000
ip -n node030 l set dev veth030001 up
ip -n node034 l set dev veth034001 mtu 9000
ip -n node034 l set dev veth034001 up
ip netns exec node030 bash -c "${ROOT}/delay.sh veth030001 10ms 1000mbit 10ms"
ip netns exec node034 bash -c "${ROOT}/delay.sh veth034001 10ms 1000mbit 10ms"
ip -n node031 l add dev veth031001 type veth peer name veth032001
ip -n node031 l set dev veth032001 netns node032
ip -n node031 l set dev veth031001 mtu 9000
ip -n node031 l set dev veth031001 up
ip -n node032 l set dev veth032001 mtu 9000
ip -n node032 l set dev veth032001 up
ip netns exec node031 bash -c "${ROOT}/delay.sh veth031001 10ms 1000mbit 10ms"
ip netns exec node032 bash -c "${ROOT}/delay.sh veth032001 10ms 1000mbit 10ms"
ip -n node033 l add dev veth033001 type veth peer name veth035001
ip -n node033 l set dev veth035001 netns node035
ip -n node033 l set dev veth033001 mtu 9000
ip -n node033 l set dev veth033001 up
ip -n node035 l set dev veth035001 mtu 9000
ip -n node035 l set dev veth035001 up
ip netns exec node033 bash -c "${ROOT}/delay.sh veth033001 10ms 1000mbit 10ms"
ip netns exec node035 bash -c "${ROOT}/delay.sh veth035001 10ms 1000mbit 10ms"
#"${ROOT}"/env/bin/python3 "${ROOT}"/setup.py ${ROOT}/links
ip netns exec node027 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node027 node027 0.0.0.0 ${TMP}"
ip netns exec node028 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node028 node028 0.0.0.0 ${TMP}"
ip netns exec node029 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node029 node029 0.0.0.0 ${TMP}"
ip netns exec node030 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node030 node030 0.0.0.0 ${TMP}"
ip netns exec node031 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node031 node031 0.0.0.0 ${TMP}"
ip netns exec node032 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node032 node032 0.0.0.0 ${TMP}"
ip netns exec node033 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node033 node033 0.0.0.0 ${TMP}"
ip netns exec node034 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node034 node034 0.0.0.0 ${TMP}"
ip netns exec node035 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node035 node035 0.0.0.0 ${TMP}"
#curl -X POST -H "Content-Type: application/json" -d "{\"topo\": \"579021709b636e877d429e38b593b2a421994116fa1fb246ee0f3112b530a9e3\", \"endpoint\": \"$(cat ${ROOT}/vnode)\"}" https://roq.info.ucl.ac.be:8080/e8b32bc4d7b564ac6075a1418ad8841e/endpoints
else
# core 0
IO_QUIC_CORE_ID=0 ip netns exec node027 bash -c "taskset -c 2 "${ROOT}"/bird -s /tmp/node027.bird.sk -c "${ROOT}"/node027.bird.cfg -P /tmp/node027.bird.pid &"
IO_QUIC_CORE_ID=4 ip netns exec node028 bash -c "taskset -c 6 "${ROOT}"/bird -s /tmp/node028.bird.sk -c "${ROOT}"/node028.bird.cfg -P /tmp/node028.bird.pid &"
IO_QUIC_CORE_ID=8 ip netns exec node029 bash -c "taskset -c 10 "${ROOT}"/bird -s /tmp/node029.bird.sk -c "${ROOT}"/node029.bird.cfg -P /tmp/node029.bird.pid &"
IO_QUIC_CORE_ID=12 ip netns exec node030 bash -c "taskset -c 14 "${ROOT}"/bird -s /tmp/node030.bird.sk -c "${ROOT}"/node030.bird.cfg -P /tmp/node030.bird.pid &"
IO_QUIC_CORE_ID=16 ip netns exec node031 bash -c "taskset -c 18 "${ROOT}"/bird -s /tmp/node031.bird.sk -c "${ROOT}"/node031.bird.cfg -P /tmp/node031.bird.pid &"
# core 1
IO_QUIC_CORE_ID=1 ip netns exec node032 bash -c "taskset -c 3 "${ROOT}"/bird -s /tmp/node032.bird.sk -c "${ROOT}"/node032.bird.cfg -P /tmp/node032.bird.pid &"
IO_QUIC_CORE_ID=5 ip netns exec node033 bash -c "taskset -c 7 "${ROOT}"/bird -s /tmp/node033.bird.sk -c "${ROOT}"/node033.bird.cfg -P /tmp/node033.bird.pid &"
IO_QUIC_CORE_ID=9 ip netns exec node034 bash -c "taskset -c 11 "${ROOT}"/bird -s /tmp/node034.bird.sk -c "${ROOT}"/node034.bird.cfg -P /tmp/node034.bird.pid &"
IO_QUIC_CORE_ID=13 ip netns exec node035 bash -c "taskset -c 15 "${ROOT}"/bird -s /tmp/node035.bird.sk -c "${ROOT}"/node035.bird.cfg -P /tmp/node035.bird.pid &"
fi
