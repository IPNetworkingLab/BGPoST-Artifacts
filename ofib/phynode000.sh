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
ip netns add node000
ip -n node000 a add fe80::1/64 dev lo
ip -n node000 a add fc00:1:: dev lo
ip -n node000 l set dev lo up
ip netns exec node000 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node000 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node000 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node000 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node000 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node001
ip -n node001 a add fe80::1/64 dev lo
ip -n node001 a add fc00:1:1:: dev lo
ip -n node001 l set dev lo up
ip netns exec node001 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node001 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node001 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node001 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node001 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node002
ip -n node002 a add fe80::1/64 dev lo
ip -n node002 a add fc00:1:2:: dev lo
ip -n node002 l set dev lo up
ip netns exec node002 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node002 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node002 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node002 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node002 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node003
ip -n node003 a add fe80::1/64 dev lo
ip -n node003 a add fc00:1:3:: dev lo
ip -n node003 l set dev lo up
ip netns exec node003 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node003 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node003 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node003 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node003 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node004
ip -n node004 a add fe80::1/64 dev lo
ip -n node004 a add fc00:1:4:: dev lo
ip -n node004 l set dev lo up
ip netns exec node004 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node004 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node004 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node004 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node004 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node005
ip -n node005 a add fe80::1/64 dev lo
ip -n node005 a add fc00:1:5:: dev lo
ip -n node005 l set dev lo up
ip netns exec node005 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node005 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node005 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node005 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node005 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node006
ip -n node006 a add fe80::1/64 dev lo
ip -n node006 a add fc00:1:6:: dev lo
ip -n node006 l set dev lo up
ip netns exec node006 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node006 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node006 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node006 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node006 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node007
ip -n node007 a add fe80::1/64 dev lo
ip -n node007 a add fc00:1:7:: dev lo
ip -n node007 l set dev lo up
ip netns exec node007 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node007 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node007 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node007 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node007 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node008
ip -n node008 a add fe80::1/64 dev lo
ip -n node008 a add fc00:1:8:: dev lo
ip -n node008 l set dev lo up
ip netns exec node008 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node008 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node008 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node008 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node008 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
./phynode000_vlans.sh
ip -n node000 l add dev veth000000 type veth peer name veth001000
ip -n node000 l set dev veth001000 netns node001
ip -n node000 l set dev veth000000 mtu 9000
ip -n node000 l set dev veth000000 up
ip -n node001 l set dev veth001000 mtu 9000
ip -n node001 l set dev veth001000 up
ip netns exec node000 bash -c "${ROOT}/delay.sh veth000000 10ms 1000mbit 10ms"
ip netns exec node001 bash -c "${ROOT}/delay.sh veth001000 10ms 1000mbit 10ms"
ip -n node000 l add dev veth000001 type veth peer name veth002000
ip -n node000 l set dev veth002000 netns node002
ip -n node000 l set dev veth000001 mtu 9000
ip -n node000 l set dev veth000001 up
ip -n node002 l set dev veth002000 mtu 9000
ip -n node002 l set dev veth002000 up
ip netns exec node000 bash -c "${ROOT}/delay.sh veth000001 10ms 1000mbit 10ms"
ip netns exec node002 bash -c "${ROOT}/delay.sh veth002000 10ms 1000mbit 10ms"
ip -n node000 l add dev veth000002 type veth peer name veth003000
ip -n node000 l set dev veth003000 netns node003
ip -n node000 l set dev veth000002 mtu 9000
ip -n node000 l set dev veth000002 up
ip -n node003 l set dev veth003000 mtu 9000
ip -n node003 l set dev veth003000 up
ip netns exec node000 bash -c "${ROOT}/delay.sh veth000002 10ms 1000mbit 10ms"
ip netns exec node003 bash -c "${ROOT}/delay.sh veth003000 10ms 1000mbit 10ms"
ip -n node000 l add dev veth000003 type veth peer name veth004000
ip -n node000 l set dev veth004000 netns node004
ip -n node000 l set dev veth000003 mtu 9000
ip -n node000 l set dev veth000003 up
ip -n node004 l set dev veth004000 mtu 9000
ip -n node004 l set dev veth004000 up
ip netns exec node000 bash -c "${ROOT}/delay.sh veth000003 10ms 1000mbit 10ms"
ip netns exec node004 bash -c "${ROOT}/delay.sh veth004000 10ms 1000mbit 10ms"
ip -n node000 l add dev veth000004 type veth peer name veth005000
ip -n node000 l set dev veth005000 netns node005
ip -n node000 l set dev veth000004 mtu 9000
ip -n node000 l set dev veth000004 up
ip -n node005 l set dev veth005000 mtu 9000
ip -n node005 l set dev veth005000 up
ip netns exec node000 bash -c "${ROOT}/delay.sh veth000004 10ms 1000mbit 10ms"
ip netns exec node005 bash -c "${ROOT}/delay.sh veth005000 10ms 1000mbit 10ms"
echo 001_001 | tee -a ${ROOT}/links
ip netns exec node001 bash -c "${ROOT}/delay.sh veth001001 10ms 1000mbit 10ms"
echo 001_002 | tee -a ${ROOT}/links
ip netns exec node001 bash -c "${ROOT}/delay.sh veth001002 10ms 1000mbit 10ms"
echo 001_003 | tee -a ${ROOT}/links
ip netns exec node001 bash -c "${ROOT}/delay.sh veth001003 10ms 1000mbit 10ms"
ip -n node002 l add dev veth002001 type veth peer name veth006000
ip -n node002 l set dev veth006000 netns node006
ip -n node002 l set dev veth002001 mtu 9000
ip -n node002 l set dev veth002001 up
ip -n node006 l set dev veth006000 mtu 9000
ip -n node006 l set dev veth006000 up
ip netns exec node002 bash -c "${ROOT}/delay.sh veth002001 10ms 1000mbit 10ms"
ip netns exec node006 bash -c "${ROOT}/delay.sh veth006000 10ms 1000mbit 10ms"
echo 002_002 | tee -a ${ROOT}/links
ip netns exec node002 bash -c "${ROOT}/delay.sh veth002002 10ms 1000mbit 10ms"
echo 003_001 | tee -a ${ROOT}/links
ip netns exec node003 bash -c "${ROOT}/delay.sh veth003001 10ms 1000mbit 10ms"
echo 003_002 | tee -a ${ROOT}/links
ip netns exec node003 bash -c "${ROOT}/delay.sh veth003002 10ms 1000mbit 10ms"
ip -n node004 l add dev veth004001 type veth peer name veth005001
ip -n node004 l set dev veth005001 netns node005
ip -n node004 l set dev veth004001 mtu 9000
ip -n node004 l set dev veth004001 up
ip -n node005 l set dev veth005001 mtu 9000
ip -n node005 l set dev veth005001 up
ip netns exec node004 bash -c "${ROOT}/delay.sh veth004001 10ms 1000mbit 10ms"
ip netns exec node005 bash -c "${ROOT}/delay.sh veth005001 10ms 1000mbit 10ms"
echo 004_002 | tee -a ${ROOT}/links
ip netns exec node004 bash -c "${ROOT}/delay.sh veth004002 10ms 1000mbit 10ms"
ip -n node006 l add dev veth006001 type veth peer name veth007000
ip -n node006 l set dev veth007000 netns node007
ip -n node006 l set dev veth006001 mtu 9000
ip -n node006 l set dev veth006001 up
ip -n node007 l set dev veth007000 mtu 9000
ip -n node007 l set dev veth007000 up
ip netns exec node006 bash -c "${ROOT}/delay.sh veth006001 10ms 1000mbit 10ms"
ip netns exec node007 bash -c "${ROOT}/delay.sh veth007000 10ms 1000mbit 10ms"
ip -n node006 l add dev veth006002 type veth peer name veth008000
ip -n node006 l set dev veth008000 netns node008
ip -n node006 l set dev veth006002 mtu 9000
ip -n node006 l set dev veth006002 up
ip -n node008 l set dev veth008000 mtu 9000
ip -n node008 l set dev veth008000 up
ip netns exec node006 bash -c "${ROOT}/delay.sh veth006002 10ms 1000mbit 10ms"
ip netns exec node008 bash -c "${ROOT}/delay.sh veth008000 10ms 1000mbit 10ms"
echo 007_001 | tee -a ${ROOT}/links
ip netns exec node007 bash -c "${ROOT}/delay.sh veth007001 10ms 1000mbit 10ms"
echo 007_002 | tee -a ${ROOT}/links
ip netns exec node007 bash -c "${ROOT}/delay.sh veth007002 10ms 1000mbit 10ms"
echo 007_003 | tee -a ${ROOT}/links
ip netns exec node007 bash -c "${ROOT}/delay.sh veth007003 10ms 1000mbit 10ms"
echo 007_004 | tee -a ${ROOT}/links
ip netns exec node007 bash -c "${ROOT}/delay.sh veth007004 10ms 1000mbit 10ms"
echo 007_005 | tee -a ${ROOT}/links
ip netns exec node007 bash -c "${ROOT}/delay.sh veth007005 10ms 1000mbit 10ms"
echo 008_001 | tee -a ${ROOT}/links
ip netns exec node008 bash -c "${ROOT}/delay.sh veth008001 10ms 1000mbit 10ms"
#"${ROOT}"/env/bin/python3 "${ROOT}"/setup.py ${ROOT}/links
ip netns exec node000 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node000 node000 0.0.0.0 ${TMP}"
ip netns exec node001 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node001 node001 0.0.0.0 ${TMP}"
ip netns exec node002 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node002 node002 0.0.0.0 ${TMP}"
ip netns exec node003 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node003 node003 0.0.0.0 ${TMP}"
ip netns exec node004 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node004 node004 0.0.0.0 ${TMP}"
ip netns exec node005 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node005 node005 0.0.0.0 ${TMP}"
ip netns exec node006 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node006 node006 0.0.0.0 ${TMP}"
ip netns exec node007 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node007 node007 0.0.0.0 ${TMP}"
ip netns exec node008 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node008 node008 0.0.0.0 ${TMP}"
#curl -X POST -H "Content-Type: application/json" -d "{\"topo\": \"579021709b636e877d429e38b593b2a421994116fa1fb246ee0f3112b530a9e3\", \"endpoint\": \"$(cat ${ROOT}/vnode)\"}" https://roq.info.ucl.ac.be:8080/e8b32bc4d7b564ac6075a1418ad8841e/endpoints
else
# core 0
IO_QUIC_CORE_ID=0 ip netns exec node000 bash -c "taskset -c 2 "${ROOT}"/bird -s /tmp/node000.bird.sk -c "${ROOT}"/node000.bird.cfg -P /tmp/node000.bird.pid &"
IO_QUIC_CORE_ID=4 ip netns exec node001 bash -c "taskset -c 6 "${ROOT}"/bird -s /tmp/node001.bird.sk -c "${ROOT}"/node001.bird.cfg -P /tmp/node001.bird.pid &"
IO_QUIC_CORE_ID=8 ip netns exec node002 bash -c "taskset -c 10 "${ROOT}"/bird -s /tmp/node002.bird.sk -c "${ROOT}"/node002.bird.cfg -P /tmp/node002.bird.pid &"
IO_QUIC_CORE_ID=12 ip netns exec node003 bash -c "taskset -c 14 "${ROOT}"/bird -s /tmp/node003.bird.sk -c "${ROOT}"/node003.bird.cfg -P /tmp/node003.bird.pid &"
IO_QUIC_CORE_ID=16 ip netns exec node004 bash -c "taskset -c 18 "${ROOT}"/bird -s /tmp/node004.bird.sk -c "${ROOT}"/node004.bird.cfg -P /tmp/node004.bird.pid &"
IO_QUIC_CORE_ID=20 ip netns exec node005 bash -c "taskset -c 22 "${ROOT}"/bird -s /tmp/node005.bird.sk -c "${ROOT}"/node005.bird.cfg -P /tmp/node005.bird.pid &"
# core 1
IO_QUIC_CORE_ID=1 ip netns exec node006 bash -c "taskset -c 3 "${ROOT}"/bird -s /tmp/node006.bird.sk -c "${ROOT}"/node006.bird.cfg -P /tmp/node006.bird.pid &"
IO_QUIC_CORE_ID=5 ip netns exec node007 bash -c "taskset -c 7 "${ROOT}"/bird -s /tmp/node007.bird.sk -c "${ROOT}"/node007.bird.cfg -P /tmp/node007.bird.pid &"
IO_QUIC_CORE_ID=9 ip netns exec node008 bash -c "taskset -c 11 "${ROOT}"/bird -s /tmp/node008.bird.sk -c "${ROOT}"/node008.bird.cfg -P /tmp/node008.bird.pid &"
fi
