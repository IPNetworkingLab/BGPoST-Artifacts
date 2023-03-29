#! /bin/bash -x

ip l add group 42 link eno4 name veth027000-vlan type vlan id 44
ip l set dev veth027000-vlan up
ip l add link veth027000-vlan name veth027000 type macvlan mode private
ip l set dev veth027000 netns node027
ip netns exec node027 ip l set dev veth027000 up
ip l add group 42 link eno4 name veth030000-vlan type vlan id 50
ip l set dev veth030000-vlan up
ip l add link veth030000-vlan name veth030000 type macvlan mode private
ip l set dev veth030000 netns node030
ip netns exec node030 ip l set dev veth030000 up
ip l add group 42 link eno4 name veth031000-vlan type vlan id 51
ip l set dev veth031000-vlan up
ip l add link veth031000-vlan name veth031000 type macvlan mode private
ip l set dev veth031000 netns node031
ip netns exec node031 ip l set dev veth031000 up
ip l add group 42 link eno4 name veth032000-vlan type vlan id 52
ip l set dev veth032000-vlan up
ip l add link veth032000-vlan name veth032000 type macvlan mode private
ip l set dev veth032000 netns node032
ip netns exec node032 ip l set dev veth032000 up
ip l add group 42 link eno4 name veth033000-vlan type vlan id 53
ip l set dev veth033000-vlan up
ip l add link veth033000-vlan name veth033000 type macvlan mode private
ip l set dev veth033000 netns node033
ip netns exec node033 ip l set dev veth033000 up
ip l add group 42 link eno4 name veth028000-vlan type vlan id 56
ip l set dev veth028000-vlan up
ip l add link veth028000-vlan name veth028000 type macvlan mode private
ip l set dev veth028000 netns node028
ip netns exec node028 ip l set dev veth028000 up
ip l add group 42 link eno4 name veth029000-vlan type vlan id 57
ip l set dev veth029000-vlan up
ip l add link veth029000-vlan name veth029000 type macvlan mode private
ip l set dev veth029000 netns node029
ip netns exec node029 ip l set dev veth029000 up
ip l add group 42 link eno4 name veth034000-vlan type vlan id 58
ip l set dev veth034000-vlan up
ip l add link veth034000-vlan name veth034000 type macvlan mode private
ip l set dev veth034000 netns node034
ip netns exec node034 ip l set dev veth034000 up
ip l add group 42 link eno4 name veth029001-vlan type vlan id 60
ip l set dev veth029001-vlan up
ip l add link veth029001-vlan name veth029001 type macvlan mode private
ip l set dev veth029001 netns node029
ip netns exec node029 ip l set dev veth029001 up
ip l add group 42 link eno4 name veth027001-vlan type vlan id 61
ip l set dev veth027001-vlan up
ip l add link veth027001-vlan name veth027001 type macvlan mode private
ip l set dev veth027001 netns node027
ip netns exec node027 ip l set dev veth027001 up
