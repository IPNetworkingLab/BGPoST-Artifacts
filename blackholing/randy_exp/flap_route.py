#!/usr/bin/env python3
import os
from argparse import ArgumentParser

import pexpect

STATUS_DOWN = 0
STATUS_UP = 1
STATUS_UNK = 2

STATUS_2_STR = {
    STATUS_UP: 'UP',
    STATUS_DOWN: 'DOWN',
    STATUS_UNK: '???'
}

BIRD_PS1 = 'bird> '


def handle_line(line: bytes, proto_name: str):
    # skip blank lines
    if line == b'\r\n':
        return None
    decoded_line = line.decode().strip()
    if decoded_line.startswith(f'{proto_name}'):
        proto_state = decoded_line.split()

        if proto_state[3] == 'up':
            return STATUS_UP
        elif proto_state[3] == 'down':
            return STATUS_DOWN
    return None


def process_child_output(child: pexpect.spawn, proto_name: str):
    while (line := child.readline()) != '':
        curr_status = handle_line(line, proto_name)
        if curr_status is not None:
            return curr_status

    return STATUS_UNK


def start_session(birdc: str, bird_sk: str):
    cmd = f"{birdc} -s {bird_sk}"
    spawned = False
    try:
        ps = pexpect.spawn(cmd)
        spawned = True
        ps.expect(BIRD_PS1)

        return ps
    except pexpect.ExceptionPexpect as e:
        if spawned:
            ps.close()
            ps.wait()
        print(f'Child error: {e}')


def get_state(cli: pexpect.spawn, proto_name: str):
    status = STATUS_UNK
    try:
        cli.sendline(f'show protocols {proto_name}')
        cli.expect(f'show protocols {proto_name}')
        idx = cli.expect(['syntax error',
                          r"Name\s+Proto\s+Table\s+State\s+Since\s+Info"])

        if idx == 0:
            print(f'Unknown proto {proto_name}')
        elif idx == 1:
            status = process_child_output(cli, proto_name)

        cli.expect(BIRD_PS1)
    except pexpect.EOF as e:
        print(f'Unexpected EOF: {e}')
    except pexpect.TIMEOUT as e:
        print(f'Timeout while running birdc: {e}')
    except pexpect.ExceptionPexpect as e:
        print(f'Child error: {e}')
    finally:
        return status


def toggle_proto(cli: pexpect.spawn, proto_name: str, toggle: bool):
    str_toggle = 'enable' if toggle else 'disable'
    expected = 'enabled' if toggle else 'disabled'

    cli.sendline(f"{str_toggle} {proto_name}")
    try:
        idx = cli.expect([f'{proto_name}: {expected}', 'syntax error'])
        if idx == 1:
            return False
        cli.expect(BIRD_PS1)
    except pexpect.EOF:
        return False
    except pexpect.TIMEOUT:
        return False

    return True


def main(args) -> bool:
    if args.proto == "":
        print("Empty proto")
        return False
    
    ret = False
    cli = start_session(args.birdc, args.socket)
    if cli is None:
        print('Unable to start birdc')
        return False

    status = get_state(cli, args.proto)
    if status == STATUS_UNK:
        print('Unknown state.')
    elif toggle_proto(cli, args.proto, not status):
        print(f'Protocol {args.proto} state: '
              f'{STATUS_2_STR[status]} --> {STATUS_2_STR[int(not status)]}')
        ret = True
    else:
        print("Failed to change proto state")

    cli.close()
    cli.wait()
    return ret


if __name__ == '__main__':
    if os.geteuid() != 0:
        print("Please run as root")
        exit(1)

    parser = ArgumentParser(description="Get the status of a Bird channel")

    parser.add_argument('-p', '--proto', required=False,
                        type=str, default='static1', help='Get status of this protocol. '
                                                          'default: static1')
    parser.add_argument('-b', '--birdc', required=True,
                        type=str, help='Path to the birdc CLI binary')
    parser.add_argument('-s', '--socket', required=True,
                        type=str, help='Socket path to the BIRD routing daemon')

    _ret = main(parser.parse_args())
    exit(0 if _ret else 1)
