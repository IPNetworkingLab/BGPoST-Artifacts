#!/usr/bin/env python3
import json
import re
import subprocess
from argparse import ArgumentParser


def handle_config(cfg: dict, netns_exclusion: list = None):
    node_creator_cfg = cfg['Nodes']
    links_creator_cfg = cfg['Links']

    for command in node_creator_cfg:
        exec_cmd(command)
    for command in links_creator_cfg:
        exec_cmd(command)


def handle_cold_start(cfg: dict, netns_exclusion: list = None):
    processes_cfg = cfg['Processes']

    for command in processes_cfg:
        exec_cmd(command)


def handle_exp(cfg: dict, netns_exclusion: list, start=True):
    processes_cfg = cfg['Processes' if start else 'Down']

    netns_regex = r"ip\s+netns\s+exec\s+(\S+).*"

    for command in processes_cfg:
        match = re.search(netns_regex, command)
        if match is None:
            continue
        netns = match.group(1)
        if netns in netns_exclusion:
            continue
        exec_cmd(command)


def handle_start(cfg: dict, netns_exclusion: list):
    handle_exp(cfg, netns_exclusion, start=True)


def handle_stop(cfg: dict, netns_exclusion: list):
    handle_exp(cfg, netns_exclusion, start=False)


def handle_destroy(cfg: dict, netns_exclusion: list = None):
    print('Well, this is not supported yet.......')


def action_handler(action: str) -> callable:
    supported_actions = {
        'config': handle_config,
        'start': handle_start,
        'cold_start': handle_cold_start,
        'stop': handle_stop,
        'destroy': handle_destroy
    }

    if action not in supported_actions:
        raise ValueError(f'Unexpected action: "{action}"\n'
                         f'Supported actions: {", ".join([i for i in supported_actions])}')

    return supported_actions[action]


def exec_cmd(cmd_str: str, enforce_success: bool = True):
    # background processes may be spawned
    c = subprocess.run(cmd_str, shell=True)
    if enforce_success:
        c.check_returncode()


def get_config(cfg_path: str):
    with open(cfg_path) as f:
        return json.load(f)


def main(args):
    dune_config = get_config(args.config)
    handler = action_handler(args.action)

    handler(dune_config, args.exclude)


if __name__ == '__main__':
    parser = ArgumentParser(description="Execute given commands in dune config")

    parser.add_argument('-c', '--config', required=True, type=str,
                        help='Config generated by Dune')

    parser.add_argument('-a', '--action', required=True, type=str,

                        help="Action to execute")

    parser.add_argument('-e', '--exclude', required=False, action='append', type=str,
                        help='Namespace to exclude when running or stopping experiment')

    main(parser.parse_args())
