#!/usr/bin/env python3

from sys import stdin

for line in stdin:
    arr = line.strip().split('|')
    print(f'{arr[5]}')
