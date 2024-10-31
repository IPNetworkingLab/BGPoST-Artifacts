# Simple BGP/TLS topology

```text
                       TLS           
                 ┌────┐  ┌────┐      
           TLS┌──┼ S2 ┼──┤ S3 ┼──┐TLS
              │  └────┘  └────┘  │   
┌───────┐  ┌──┼─┐              ┌─┼──┐
│ GoBGP ├──┤ S1 │              │ S6 │
└───────┘  └──┬─┘              └─┬──┘
              │  ┌────┐  ┌────┐  │   
           TCP└──┼ S4 ├──┼ S5 ┼──┘TCP
                 └────┘  └────┘      
                       TCP       
```

This simple example topology contained in `bgptls.clab.yml` deploys a ring topology.

The sessions:

    - S1 <-> S2
    - S2 <-> S3
    - S3 <-> S6

Are established using BGP over TLS/TCP.

The sessions:

    - GoBGP <-> S1
    - S1 <-> S4
    - S4 <-> S5
    - S5 <-> S6

Are using a classic BGP over TCP session.

## Running the lab

You must first install the prerequisites:

``` text
docker, containerlab, openssl
```

Then simply run:

```sh
$ ./run.sh
```

To access to any container:

```sh
$ docker exec -it clab-BGPoTLS-{xx} ash
```

Where `{xx}` is the node name of the router you would like to access.

For example to access to the `s3` node, the command is:

```sh
$ docker exec -it clab-BGPoTLS-s3 ash
```

You will enter to a shell representing your virtual node. If you would like to access to the `birdc` remote control,
simply enter `birdc` to the virtual shell.

Another option is to pass directly the command to run inside the container:

```sh
$ docker exec -it clab-BGPoTLS-s3 birdc
```

