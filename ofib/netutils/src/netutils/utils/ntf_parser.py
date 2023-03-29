import os

import matplotlib.pyplot as plt
import networkx as nx


def parse_ntf(content: str):

    g = nx.MultiGraph()

    for line in content.splitlines():
        if line[0] == '#': continue

        head, tail, metric, latency = line.split(' ')

        if head not in g:
            g.add_node(head)

        if tail not in g:
            g.add_node(tail)

        edges = g.edges(data='reverse_metric')

        edge = (head, tail)

        if (tail, head) not in (edges := g.edges()): 
            g.add_edge(head, tail, forward_metric=int(metric), reverse_metric=-1, latency=float(latency))
        else:
            """ The link already exists. Is this an non-complete or a redundant one? """
            completed = False
            for _, edge in g[tail][head].items():
                """ Iterate on all the links """
                if edge['reverse_metric'] == -1:
                    """ If the reverse metric is empty, we update it """
                    edge['reverse_metric'] = int(metric)
                    completed = True
                    break
                elif edge['forward_metric'] == -1:
                    edge['forward_metric'] = int(metric)
                    completed = True
                    break

            if not completed:
                """ If we didn't find a link with missing metric, then we found a new redundant link """
                g.add_edge(head, tail, forward_metric=int(metric), reverse_metric=-1, latency=float(latency))

    return g


def get_content(path: str) -> str:
    path = os.path.abspath(path)
    if not os.path.exists(path):
        print('The provided path does not exists')
        exit(1)

    with open(path, 'r') as fd:
        content = fd.read()

    return content


def parse(path: str) -> nx.MultiGraph:
    content = get_content(path)
    return parse_ntf(content)


def convert(path: str, graph: nx.MultiGraph = None) -> str:

    """
    def _convert(path: str) -> dict:
        content = get_content(path)
        result = {}
        for head, tail, data in content.edges(data=True):
            try:
                result[(head, tail)].append(data)
            except KeyError:
                result[(head, tail)] = list(data)
        return result
    """

    root, name = os.path.split(path)
    name, _ = os.path.splitext(name)
    new_file = os.path.join(root, '%s%s'% (name, '.tmp'))

    content = get_content(path) if graph is None else graph
    nodes = list(content.nodes())

    with open(new_file, 'w') as fd:
        for head, tail, data in content.edges(data=True):
            line = ','.join([str(i) for i in [nodes.index(head), nodes.index(tail), data['forward_metric'], data['reverse_metric'], int(data['latency'])]])
            fd.write(line + '\n')

    return new_file


def cli(args: dict):
    ntf = args.ntf
    graph = parse(ntf)

    if args.convert: convert(ntf, graph)

    print(graph)
    print(graph.nodes)
    print(graph.edges(data=True))


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('ntf', help='Path towards the NTF file to parse')
    parser.add_argument('--convert', action='store_true', default=False)
    
    args = parser.parse_args()

    cli(args)
