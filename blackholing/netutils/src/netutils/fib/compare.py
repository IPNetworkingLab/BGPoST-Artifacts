import subprocess as sp
import json

from networkx import all_pairs_dijkstra

from netutils.fib.parser import Parser as FibParser
from netutils.utils.ntf_parser import parse as NtfParser, convert as NtfConvert

class Comparator:
    def __init__(self, ntf, dumps):
        self.ntf = ntf
        self.output = '/tmp/table.prediction'
        self.topo = NtfParser(ntf)
        self.converted = NtfConvert(ntf, self.topo)
        self.collected_routes = FibParser(dumps).get_routes()

        self._predict_routes()


    def _predict_routes(self):
        # TODO remove hardcoded path and embed rust module in python package
        # TODO make output configurable
        cargo_path = "/tmp/netutils/rust_bindings/flop/Cargo.toml"
        cmd = 'cargo run --manifest-path=%s -- --path %s --output %s' % (cargo_path, self.converted, self.output)
        sp.run(cmd.split())
        with open(self.output, 'r') as fd:
            self.predicted_routes = json.load(fd) 

    def compare(self):
        predicted = '/tmp/table.prediction'
        with open(predicted, 'r') as fd:
            prediction = json.load(fd)

        prediction = {int(head): {int(tail): routes for tail, routes in data.items()} for head, data in prediction.items()}

        for head, data in self.collected_routes.items():
            if head not in prediction:
                print('Node <%i> not found in predicted routes' % head)
                continue

            for tail, routes in data.items():
                if tail not in prediction[head]:
                    print('Node <%i> not found in predicted routes' % tail)
                    continue

                collected_routes = set([tuple(route) for route in routes])
                predicted_routes = set([tuple(route) for route in prediction[head][tail]])
                print(collected_routes, predicted_routes)
                assert collected_routes == predicted_routes


def cli(args: dict):
    comparator = Comparator(args.ntf, args.dumps)
    comparator.compare()


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('ntf')
    parser.add_argument('dumps')
    args = parser.parse_args()
    cli(args)
