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
ip netns add node009
ip -n node009 a add fe80::1/64 dev lo
ip -n node009 a add fc00:1:9:: dev lo
ip -n node009 l set dev lo up
ip netns exec node009 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node009 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node009 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node009 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node009 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node010
ip -n node010 a add fe80::1/64 dev lo
ip -n node010 a add fc00:1:a:: dev lo
ip -n node010 l set dev lo up
ip netns exec node010 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node010 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node010 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node010 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node010 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node011
ip -n node011 a add fe80::1/64 dev lo
ip -n node011 a add fc00:1:b:: dev lo
ip -n node011 l set dev lo up
ip netns exec node011 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node011 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node011 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node011 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node011 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node012
ip -n node012 a add fe80::1/64 dev lo
ip -n node012 a add fc00:1:c:: dev lo
ip -n node012 l set dev lo up
ip netns exec node012 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node012 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node012 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node012 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node012 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node013
ip -n node013 a add fe80::1/64 dev lo
ip -n node013 a add fc00:1:d:: dev lo
ip -n node013 l set dev lo up
ip netns exec node013 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node013 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node013 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node013 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node013 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node014
ip -n node014 a add fe80::1/64 dev lo
ip -n node014 a add fc00:1:e:: dev lo
ip -n node014 l set dev lo up
ip netns exec node014 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node014 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node014 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node014 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node014 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node015
ip -n node015 a add fe80::1/64 dev lo
ip -n node015 a add fc00:1:f:: dev lo
ip -n node015 l set dev lo up
ip netns exec node015 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node015 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node015 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node015 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node015 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node016
ip -n node016 a add fe80::1/64 dev lo
ip -n node016 a add fc00:1:10:: dev lo
ip -n node016 l set dev lo up
ip netns exec node016 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node016 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node016 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node016 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node016 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
ip netns add node017
ip -n node017 a add fe80::1/64 dev lo
ip -n node017 a add fc00:1:11:: dev lo
ip -n node017 l set dev lo up
ip netns exec node017 bash -c "sysctl -w net.ipv4.ip_forward=1"
ip netns exec node017 bash -c "sysctl -w net.ipv6.conf.all.forwarding=1"
ip netns exec node017 bash -c "sysctl -w net.ipv6.conf.default.keep_addr_on_down=1"
ip netns exec node017 bash -c "sysctl -w net.ipv6.conf.all.keep_addr_on_down=1"
ip netns exec node017 bash -c "sysctl -w net.ipv4.udp_rmem_min=4096000 net.core.rmem_max=26214400 net.core.rmem_default=26214400 net.core.netdev_max_backlog=2000"
./phynode001_vlans.sh
echo 009_000 | tee -a ${ROOT}/links
ip netns exec node009 bash -c "${ROOT}/delay.sh veth009000 10ms 1000mbit 10ms"
echo 009_001 | tee -a ${ROOT}/links
ip netns exec node009 bash -c "${ROOT}/delay.sh veth009001 10ms 1000mbit 10ms"
echo 010_000 | tee -a ${ROOT}/links
ip netns exec node010 bash -c "${ROOT}/delay.sh veth010000 10ms 1000mbit 10ms"
echo 013_000 | tee -a ${ROOT}/links
ip netns exec node013 bash -c "${ROOT}/delay.sh veth013000 10ms 1000mbit 10ms"
echo 010_001 | tee -a ${ROOT}/links
ip netns exec node010 bash -c "${ROOT}/delay.sh veth010001 10ms 1000mbit 10ms"
ip -n node010 l add dev veth010002 type veth peer name veth011000
ip -n node010 l set dev veth011000 netns node011
ip -n node010 l set dev veth010002 mtu 9000
ip -n node010 l set dev veth010002 up
ip -n node011 l set dev veth011000 mtu 9000
ip -n node011 l set dev veth011000 up
ip netns exec node010 bash -c "${ROOT}/delay.sh veth010002 10ms 1000mbit 10ms"
ip netns exec node011 bash -c "${ROOT}/delay.sh veth011000 10ms 1000mbit 10ms"
ip -n node010 l add dev veth010003 type veth peer name veth016000
ip -n node010 l set dev veth016000 netns node016
ip -n node010 l set dev veth010003 mtu 9000
ip -n node010 l set dev veth010003 up
ip -n node016 l set dev veth016000 mtu 9000
ip -n node016 l set dev veth016000 up
ip netns exec node010 bash -c "${ROOT}/delay.sh veth010003 10ms 1000mbit 10ms"
ip netns exec node016 bash -c "${ROOT}/delay.sh veth016000 10ms 1000mbit 10ms"
echo 010_004 | tee -a ${ROOT}/links
ip netns exec node010 bash -c "${ROOT}/delay.sh veth010004 10ms 1000mbit 10ms"
ip -n node010 l add dev veth010005 type veth peer name veth014000
ip -n node010 l set dev veth014000 netns node014
ip -n node010 l set dev veth010005 mtu 9000
ip -n node010 l set dev veth010005 up
ip -n node014 l set dev veth014000 mtu 9000
ip -n node014 l set dev veth014000 up
ip netns exec node010 bash -c "${ROOT}/delay.sh veth010005 10ms 1000mbit 10ms"
ip netns exec node014 bash -c "${ROOT}/delay.sh veth014000 10ms 1000mbit 10ms"
ip -n node011 l add dev veth011001 type veth peer name veth012000
ip -n node011 l set dev veth012000 netns node012
ip -n node011 l set dev veth011001 mtu 9000
ip -n node011 l set dev veth011001 up
ip -n node012 l set dev veth012000 mtu 9000
ip -n node012 l set dev veth012000 up
ip netns exec node011 bash -c "${ROOT}/delay.sh veth011001 10ms 1000mbit 10ms"
ip netns exec node012 bash -c "${ROOT}/delay.sh veth012000 10ms 1000mbit 10ms"
ip -n node012 l add dev veth012001 type veth peer name veth015000
ip -n node012 l set dev veth015000 netns node015
ip -n node012 l set dev veth012001 mtu 9000
ip -n node012 l set dev veth012001 up
ip -n node015 l set dev veth015000 mtu 9000
ip -n node015 l set dev veth015000 up
ip netns exec node012 bash -c "${ROOT}/delay.sh veth012001 10ms 1000mbit 10ms"
ip netns exec node015 bash -c "${ROOT}/delay.sh veth015000 10ms 1000mbit 10ms"
ip -n node013 l add dev veth013001 type veth peer name veth014001
ip -n node013 l set dev veth014001 netns node014
ip -n node013 l set dev veth013001 mtu 9000
ip -n node013 l set dev veth013001 up
ip -n node014 l set dev veth014001 mtu 9000
ip -n node014 l set dev veth014001 up
ip netns exec node013 bash -c "${ROOT}/delay.sh veth013001 10ms 1000mbit 10ms"
ip netns exec node014 bash -c "${ROOT}/delay.sh veth014001 10ms 1000mbit 10ms"
echo 014_002 | tee -a ${ROOT}/links
ip netns exec node014 bash -c "${ROOT}/delay.sh veth014002 10ms 1000mbit 10ms"
ip -n node014 l add dev veth014003 type veth peer name veth017000
ip -n node014 l set dev veth017000 netns node017
ip -n node014 l set dev veth014003 mtu 9000
ip -n node014 l set dev veth014003 up
ip -n node017 l set dev veth017000 mtu 9000
ip -n node017 l set dev veth017000 up
ip netns exec node014 bash -c "${ROOT}/delay.sh veth014003 10ms 1000mbit 10ms"
ip netns exec node017 bash -c "${ROOT}/delay.sh veth017000 10ms 1000mbit 10ms"
echo 014_004 | tee -a ${ROOT}/links
ip netns exec node014 bash -c "${ROOT}/delay.sh veth014004 10ms 1000mbit 10ms"
echo 015_001 | tee -a ${ROOT}/links
ip netns exec node015 bash -c "${ROOT}/delay.sh veth015001 10ms 1000mbit 10ms"
ip -n node016 l add dev veth016001 type veth peer name veth017001
ip -n node016 l set dev veth017001 netns node017
ip -n node016 l set dev veth016001 mtu 9000
ip -n node016 l set dev veth016001 up
ip -n node017 l set dev veth017001 mtu 9000
ip -n node017 l set dev veth017001 up
ip netns exec node016 bash -c "${ROOT}/delay.sh veth016001 10ms 1000mbit 10ms"
ip netns exec node017 bash -c "${ROOT}/delay.sh veth017001 10ms 1000mbit 10ms"
echo 016_002 | tee -a ${ROOT}/links
ip netns exec node016 bash -c "${ROOT}/delay.sh veth016002 10ms 1000mbit 10ms"
echo 017_002 | tee -a ${ROOT}/links
ip netns exec node017 bash -c "${ROOT}/delay.sh veth017002 10ms 1000mbit 10ms"
#"${ROOT}"/env/bin/python3 "${ROOT}"/setup.py ${ROOT}/links
ip netns exec node009 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node009 node009 0.0.0.0 ${TMP}"
ip netns exec node010 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node010 node010 0.0.0.0 ${TMP}"
ip netns exec node011 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node011 node011 0.0.0.0 ${TMP}"
ip netns exec node012 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node012 node012 0.0.0.0 ${TMP}"
ip netns exec node013 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node013 node013 0.0.0.0 ${TMP}"
ip netns exec node014 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node014 node014 0.0.0.0 ${TMP}"
ip netns exec node015 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node015 node015 0.0.0.0 ${TMP}"
ip netns exec node016 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node016 node016 0.0.0.0 ${TMP}"
ip netns exec node017 bash -c "sh "${ROOT}"/generate_certs.sh /tmp node017 node017 0.0.0.0 ${TMP}"
#curl -X POST -H "Content-Type: application/json" -d "{\"topo\": \"579021709b636e877d429e38b593b2a421994116fa1fb246ee0f3112b530a9e3\", \"endpoint\": \"$(cat ${ROOT}/vnode)\"}" https://roq.info.ucl.ac.be:8080/e8b32bc4d7b564ac6075a1418ad8841e/endpoints
else
# core 0
IO_QUIC_CORE_ID=0 ip netns exec node009 bash -c "taskset -c 2 "${ROOT}"/bird -s /tmp/node009.bird.sk -c "${ROOT}"/node009.bird.cfg -P /tmp/node009.bird.pid &"
IO_QUIC_CORE_ID=4 ip netns exec node010 bash -c "taskset -c 6 "${ROOT}"/bird -s /tmp/node010.bird.sk -c "${ROOT}"/node010.bird.cfg -P /tmp/node010.bird.pid &"
IO_QUIC_CORE_ID=8 ip netns exec node011 bash -c "taskset -c 10 "${ROOT}"/bird -s /tmp/node011.bird.sk -c "${ROOT}"/node011.bird.cfg -P /tmp/node011.bird.pid &"
IO_QUIC_CORE_ID=12 ip netns exec node012 bash -c "taskset -c 14 "${ROOT}"/bird -s /tmp/node012.bird.sk -c "${ROOT}"/node012.bird.cfg -P /tmp/node012.bird.pid &"
IO_QUIC_CORE_ID=16 ip netns exec node013 bash -c "taskset -c 18 "${ROOT}"/bird -s /tmp/node013.bird.sk -c "${ROOT}"/node013.bird.cfg -P /tmp/node013.bird.pid &"
IO_QUIC_CORE_ID=20 ip netns exec node014 bash -c "taskset -c 22 "${ROOT}"/bird -s /tmp/node014.bird.sk -c "${ROOT}"/node014.bird.cfg -P /tmp/node014.bird.pid &"
# core 1
IO_QUIC_CORE_ID=1 ip netns exec node015 bash -c "taskset -c 3 "${ROOT}"/bird -s /tmp/node015.bird.sk -c "${ROOT}"/node015.bird.cfg -P /tmp/node015.bird.pid &"
IO_QUIC_CORE_ID=5 ip netns exec node016 bash -c "taskset -c 7 "${ROOT}"/bird -s /tmp/node016.bird.sk -c "${ROOT}"/node016.bird.cfg -P /tmp/node016.bird.pid &"
IO_QUIC_CORE_ID=9 ip netns exec node017 bash -c "taskset -c 11 "${ROOT}"/bird -s /tmp/node017.bird.sk -c "${ROOT}"/node017.bird.cfg -P /tmp/node017.bird.pid &"
fi
