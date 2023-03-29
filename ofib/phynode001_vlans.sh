#! /bin/bash -x

ip l add group 42 link eno8403 name veth009000-vlan type vlan id 45
ip l set dev veth009000-vlan up
ip l add link veth009000-vlan name veth009000 type macvlan mode private
ip l set dev veth009000 netns node009
ip netns exec node009 ip l set dev veth009000 up
ip l add group 42 link eno8403 name veth009001-vlan type vlan id 46
ip l set dev veth009001-vlan up
ip l add link veth009001-vlan name veth009001 type macvlan mode private
ip l set dev veth009001 netns node009
ip netns exec node009 ip l set dev veth009001 up
ip l add group 42 link eno8403 name veth010000-vlan type vlan id 47
ip l set dev veth010000-vlan up
ip l add link veth010000-vlan name veth010000 type macvlan mode private
ip l set dev veth010000 netns node010
ip netns exec node010 ip l set dev veth010000 up
ip l add group 42 link eno8403 name veth013000-vlan type vlan id 48
ip l set dev veth013000-vlan up
ip l add link veth013000-vlan name veth013000 type macvlan mode private
ip l set dev veth013000 netns node013
ip netns exec node013 ip l set dev veth013000 up
ip l add group 42 link eno8403 name veth010001-vlan type vlan id 49
ip l set dev veth010001-vlan up
ip l add link veth010001-vlan name veth010001 type macvlan mode private
ip l set dev veth010001 netns node010
ip netns exec node010 ip l set dev veth010001 up
ip l add group 42 link eno8403 name veth010004-vlan type vlan id 55
ip l set dev veth010004-vlan up
ip l add link veth010004-vlan name veth010004 type macvlan mode private
ip l set dev veth010004 netns node010
ip netns exec node010 ip l set dev veth010004 up
ip l add group 42 link eno8403 name veth014002-vlan type vlan id 56
ip l set dev veth014002-vlan up
ip l add link veth014002-vlan name veth014002 type macvlan mode private
ip l set dev veth014002 netns node014
ip netns exec node014 ip l set dev veth014002 up
ip l add group 42 link eno8403 name veth014004-vlan type vlan id 57
ip l set dev veth014004-vlan up
ip l add link veth014004-vlan name veth014004 type macvlan mode private
ip l set dev veth014004 netns node014
ip netns exec node014 ip l set dev veth014004 up
ip l add group 42 link eno8403 name veth015001-vlan type vlan id 58
ip l set dev veth015001-vlan up
ip l add link veth015001-vlan name veth015001 type macvlan mode private
ip l set dev veth015001 netns node015
ip netns exec node015 ip l set dev veth015001 up
ip l add group 42 link eno8403 name veth016002-vlan type vlan id 59
ip l set dev veth016002-vlan up
ip l add link veth016002-vlan name veth016002 type macvlan mode private
ip l set dev veth016002 netns node016
ip netns exec node016 ip l set dev veth016002 up
ip l add group 42 link eno8403 name veth017002-vlan type vlan id 60
ip l set dev veth017002-vlan up
ip l add link veth017002-vlan name veth017002 type macvlan mode private
ip l set dev veth017002 netns node017
ip netns exec node017 ip l set dev veth017002 up
