from defusedxml.ElementTree import parse

et = parse('renater.xml')

mapping = {
    'phynode000': {'name': 'pita', 'iface': 'eno8403', 'switch': 'eth0'},
    'phynode001': {'name': 'baguette', 'iface': 'eno8403', 'switch': 'eth1'},
    'phynode002': {'name': 'parlenka', 'iface': 'eno4', 'switch': 'eth2'},
    'phynode003': {'name': 'melonpan', 'iface': 'eno4', 'switch': 'eth3'},
}

reverse_mapping = {data['name']: phynode for phynode, data in mapping.items()}

links = {}
for phynode in mapping.keys():
    with open(f'{phynode}.sh', 'r') as fd:
        data = fd.read()
    for line in data.splitlines():
        if 'links' in line and 'tee' in line:
            node, iface = line.split(' | ')[0].split(' ')[-1].split('_')
            try:
                links[node]['ifaces'].append(iface)
            except KeyError:
                links[node] = {'ifaces': [iface], 'count': 0}
start = 42
content = {}

def add(node, iface, start):
    global content
    global mapping
    global links

    phynode = iface.split(':')[0]
    phy_iface_name = mapping[phynode]['iface']


    n = node[-3:]
    virt_iface = links[n]['ifaces'][links[n]['count']]
    virt_iface_name = f'veth{n}{virt_iface}'
    links[n]['count'] += 1

    cmd = f'ip l add group 42 link {phy_iface_name} name {virt_iface_name}-vlan type vlan id {start}\n'
    cmd += f'ip l set dev {virt_iface_name}-vlan up\n'
    cmd += f'ip l add link {virt_iface_name}-vlan name {virt_iface_name} type macvlan mode private\n'
    cmd += f'ip l set dev {virt_iface_name} netns {node}\n'
    cmd += f'ip netns exec {node} ip l set dev {virt_iface_name} up'

    try:
        content[phynode].append(cmd) 
    except KeyError:
        content[phynode] = [cmd] 

    switch_name = mapping[phynode]['switch']
    cmd = f'bridge vlan add vid {start} dev {switch_name}'

    try:
        content['switch'].append(cmd)
    except KeyError:
        content['switch'] = [cmd]


#import socket
#me = socket.gethostname()
#me = 'phynode000'

for i in et.getroot():
    if i.tag == '{http://www.geni.net/resources/rspec/3}link':
        link = i.attrib['client_id']
        head, tail, _ = link.split('_')
        ifaces = []
        for j in i:
            if j.tag == '{http://www.geni.net/resources/rspec/3}interface_ref':
                iface = j.attrib['client_id']
                ifaces.append(iface)

        add(head, ifaces[0], start)
        add(tail, ifaces[1], start)
        start += 1

print(reverse_mapping)
print()
for phynode, cmds in content.items():
    with open(f'{phynode}_vlans.sh', 'w') as fd:
        fd.write('#! /bin/bash -x\n\n')
        for cmd in cmds:
            fd.write(cmd+'\n')
