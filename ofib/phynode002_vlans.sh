#! /bin/bash -x

ip l add group 42 link eno4 name veth025000-vlan type vlan id 42
ip l set dev veth025000-vlan up
ip l add link veth025000-vlan name veth025000 type macvlan mode private
ip l set dev veth025000 netns node025
ip netns exec node025 ip l set dev veth025000 up
ip l add group 42 link eno4 name veth024000-vlan type vlan id 43
ip l set dev veth024000-vlan up
ip l add link veth024000-vlan name veth024000 type macvlan mode private
ip l set dev veth024000 netns node024
ip netns exec node024 ip l set dev veth024000 up
ip l add group 42 link eno4 name veth023000-vlan type vlan id 54
ip l set dev veth023000-vlan up
ip l add link veth023000-vlan name veth023000 type macvlan mode private
ip l set dev veth023000 netns node023
ip netns exec node023 ip l set dev veth023000 up
ip l add group 42 link eno4 name veth018000-vlan type vlan id 55
ip l set dev veth018000-vlan up
ip l add link veth018000-vlan name veth018000 type macvlan mode private
ip l set dev veth018000 netns node018
ip netns exec node018 ip l set dev veth018000 up
ip l add group 42 link eno4 name veth018001-vlan type vlan id 59
ip l set dev veth018001-vlan up
ip l add link veth018001-vlan name veth018001 type macvlan mode private
ip l set dev veth018001 netns node018
ip netns exec node018 ip l set dev veth018001 up
ip l add group 42 link eno4 name veth020001-vlan type vlan id 61
ip l set dev veth020001-vlan up
ip l add link veth020001-vlan name veth020001 type macvlan mode private
ip l set dev veth020001 netns node020
ip netns exec node020 ip l set dev veth020001 up
