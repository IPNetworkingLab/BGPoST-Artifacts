#! /usr/bin/env python3

import argparse
import sys
import os

from netutils.utils.ntf_parser import cli as utils_ntf_cli
from netutils.fib.compare import cli as fib_compare_cli
from netutils.fib.parser import cli as fib_parser_cli

def fib_collect_cmd(args: dict):

    from netutils.fib.collector import collect, dump

    prefix = '/tmp/dumps'
    data = collect()
    dump(data, prefix, args.namespace)

"""
class FIB:
    def __init(self, parser):
        parsers = subparsers.add_parser('fib')
        self.parsers = parser.add_subparsers(dest='cmd')

    def add_collect(self):

        fib_collect = fib_subparsers.add_parser('collect')
        fib_collect.add_argument('namespace')
        fib_collect.set_defaults(func=fib_collect_cmd)

        fib_parser = fib_subparsers.add_parser('parse')
        fib_parser.add_argument('prefix')
        fib_parser.set_defaults(func=fib_parser_cli)

        fib_compare = fib_subparsers.add_parser('compare')
        fib_compare.add_argument('ntf')
        fib_compare.add_argument('dumps')
        fib_compare.set_defaults(func=fib_compare_cli)
"""


def main():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest='cmd')

    fib = subparsers.add_parser('fib')
    fib_subparsers = fib.add_subparsers(dest='cmd')

    fib_collect = fib_subparsers.add_parser('collect')
    fib_collect.add_argument('namespace')
    fib_collect.set_defaults(func=fib_collect_cmd)

    fib_parser = fib_subparsers.add_parser('parse')
    fib_parser.add_argument('prefix')
    fib_parser.set_defaults(func=fib_parser_cli)

    fib_compare = fib_subparsers.add_parser('compare')
    fib_compare.add_argument('ntf')
    fib_compare.add_argument('dumps')
    fib_compare.set_defaults(func=fib_compare_cli)


    utils = subparsers.add_parser('utils')
    utils_subparser = utils.add_subparsers(dest='cmd')

    utils_ntf = utils_subparser.add_parser('ntf')
    utils_ntf.add_argument('ntf')
    utils_ntf.add_argument('--convert', action='store_true', default=False)
    utils_ntf.set_defaults(func=utils_ntf_cli)

    args = parser.parse_args()
    args.func(args)

if __name__ == '__main__':
    main()


