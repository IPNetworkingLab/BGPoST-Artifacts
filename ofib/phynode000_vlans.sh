#! /bin/bash -x

ip l add group 42 link eno8403 name veth001001-vlan type vlan id 42
ip l set dev veth001001-vlan up
ip l add link veth001001-vlan name veth001001 type macvlan mode private
ip l set dev veth001001 netns node001
ip netns exec node001 ip l set dev veth001001 up
ip l add group 42 link eno8403 name veth001002-vlan type vlan id 43
ip l set dev veth001002-vlan up
ip l add link veth001002-vlan name veth001002 type macvlan mode private
ip l set dev veth001002 netns node001
ip netns exec node001 ip l set dev veth001002 up
ip l add group 42 link eno8403 name veth001003-vlan type vlan id 44
ip l set dev veth001003-vlan up
ip l add link veth001003-vlan name veth001003 type macvlan mode private
ip l set dev veth001003 netns node001
ip netns exec node001 ip l set dev veth001003 up
ip l add group 42 link eno8403 name veth002002-vlan type vlan id 45
ip l set dev veth002002-vlan up
ip l add link veth002002-vlan name veth002002 type macvlan mode private
ip l set dev veth002002 netns node002
ip netns exec node002 ip l set dev veth002002 up
ip l add group 42 link eno8403 name veth003001-vlan type vlan id 46
ip l set dev veth003001-vlan up
ip l add link veth003001-vlan name veth003001 type macvlan mode private
ip l set dev veth003001 netns node003
ip netns exec node003 ip l set dev veth003001 up
ip l add group 42 link eno8403 name veth003002-vlan type vlan id 47
ip l set dev veth003002-vlan up
ip l add link veth003002-vlan name veth003002 type macvlan mode private
ip l set dev veth003002 netns node003
ip netns exec node003 ip l set dev veth003002 up
ip l add group 42 link eno8403 name veth004002-vlan type vlan id 48
ip l set dev veth004002-vlan up
ip l add link veth004002-vlan name veth004002 type macvlan mode private
ip l set dev veth004002 netns node004
ip netns exec node004 ip l set dev veth004002 up
ip l add group 42 link eno8403 name veth007001-vlan type vlan id 49
ip l set dev veth007001-vlan up
ip l add link veth007001-vlan name veth007001 type macvlan mode private
ip l set dev veth007001 netns node007
ip netns exec node007 ip l set dev veth007001 up
ip l add group 42 link eno8403 name veth007002-vlan type vlan id 50
ip l set dev veth007002-vlan up
ip l add link veth007002-vlan name veth007002 type macvlan mode private
ip l set dev veth007002 netns node007
ip netns exec node007 ip l set dev veth007002 up
ip l add group 42 link eno8403 name veth007003-vlan type vlan id 51
ip l set dev veth007003-vlan up
ip l add link veth007003-vlan name veth007003 type macvlan mode private
ip l set dev veth007003 netns node007
ip netns exec node007 ip l set dev veth007003 up
ip l add group 42 link eno8403 name veth007004-vlan type vlan id 52
ip l set dev veth007004-vlan up
ip l add link veth007004-vlan name veth007004 type macvlan mode private
ip l set dev veth007004 netns node007
ip netns exec node007 ip l set dev veth007004 up
ip l add group 42 link eno8403 name veth007005-vlan type vlan id 53
ip l set dev veth007005-vlan up
ip l add link veth007005-vlan name veth007005 type macvlan mode private
ip l set dev veth007005 netns node007
ip netns exec node007 ip l set dev veth007005 up
ip l add group 42 link eno8403 name veth008001-vlan type vlan id 54
ip l set dev veth008001-vlan up
ip l add link veth008001-vlan name veth008001 type macvlan mode private
ip l set dev veth008001 netns node008
ip netns exec node008 ip l set dev veth008001 up
