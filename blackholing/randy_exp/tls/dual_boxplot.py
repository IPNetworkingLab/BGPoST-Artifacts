#!/usr/bin/env python3
import pickle
from argparse import ArgumentParser

from matplotlib import pyplot as plt


def main(args):
    with open(args.tls, 'rb') as f:
        tls_times = pickle.load(f)
    with open(args.tcp, 'rb') as f:
        tcp_times = pickle.load(f)

    fig, ax = plt.subplots()

    ax.boxplot((tcp_times, tls_times), labels=('Classic\nBlackhole', 'Dynamic Secure\nBlackhole'),
               positions=[1, 1.2])
    ax.set_ylabel('Advertisement Time (ms)')
    ax.grid()
    ax.set_ylim((300, 3000))
    ax.set_xlim((0.9, 1.3))

    left, bottom, width, height = [0.63, 0.55, 0.325, 0.36]
    ax2 = fig.add_axes([left, bottom, width, height])

    ax2.boxplot(tls_times, labels=('Dynamic Secure\nBlackhole',))
    ax2.grid()

    plt.tight_layout()
    plt.show()


if __name__ == '__main__':
    parser = ArgumentParser(description="")
    parser.add_argument('--tls', dest='tls', required=True, type=str,
                        help="Pickle file containing experiment time for the TLS solution")
    parser.add_argument('--tcp', dest='tcp', required=True, type=str,
                        help='Pickle file containing experiments times for the TCP classic solution')

    main(parser.parse_args())
