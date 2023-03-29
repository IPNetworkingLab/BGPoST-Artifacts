import argparse
import socket

from jinja2 import Environment, DictLoader, select_autoescape

from myutils import node_exec, id_from_name, id_to_name, lo_from_id

bird_config = """log "/tmp/{{node_name}}.bird.log" all;
debug protocols all;
debug channels all;
debug latency on;
router id {{rid}};
protocol device {};
protocol direct {
    disabled;
    ipv4;
    ipv6;
}
protocol kernel {
    learn;
    scan time 10;
    ipv6 {
        export all;
        import all;
        export filter {
            krt_prefsrc={{lo}};
            accept;
        };
    };
}

protocol ospf v3 {
    debug all;
    ecmp yes;
    ipv6 {
        import all;
        export all;
    };
    area 0 {
    {% for iface in ifaces %}
        interface "{{iface}}" {
            link lsa suppression yes;
            cost {{cost[iface]}};
            hello 5;
        };
    {% endfor %}
        interface "lo" {
            stub yes;
        };
    };
}
"""

env = Environment(
        loader=DictLoader({'bird_config': bird_config}),
    autoescape=select_autoescape()
)

def discover_ifaces(node_id: int):

    ifaces = []
    raw_cmd = node_exec(node_id, 'ip l')
    raw_ifaces = raw_cmd.stdout.decode('utf-8')
    for line in raw_ifaces.splitlines():
        if not 'veth' in line: continue
        ifaces.append(line.split('@')[0].split(' ')[-1])
    return ifaces

def generate_bird_config(node_id: int, ifaces: list):

    template = env.get_template('bird_config')

    node_config = template.render({
        'node_name': id_to_name(node_id),
        'rid': socket.inet_ntop(socket.AF_INET, int(node_id+1).to_bytes(4,'big')),
        'lo': lo_from_id(node_id),
        'ifaces': ifaces,
        'cost': {iface: '1' for iface in ifaces}
    })

    with open('/tmp/node%s.bird.cfg' % str(node_id).zfill(3), 'w') as fd:
        fd.write(node_config)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('node_name', type=str, help='The name of the node for which we configure BIRD.')

    args = parser.parse_args()
    node_id = id_from_name(args.node_name)

    ifaces = discover_ifaces(node_id)
    generate_bird_config(node_id, ifaces)
