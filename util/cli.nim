#[
    Author: Roger Johnston, Twitter: @VV_X_7
    License: GNU AGPLv3
]#

proc writeHelp*() =
    ## Writes the cli help page.
    ##
    echo """Nicodemus
    A Nim RAT for the Prelude adversary emulation platform.

    Usage: nicodemus [-h] [-v] [--name foo] [--contact tcp] [--address 0.0.0.0:2323] [--range red] [--sleep 60]

    optional arguments:
        -h, --help  show this help message and exit
        -v, --version  show the agent version and exit
        --name  the name of the agent
        --contact  the network protocol
        --address  the ip:port of the listening socket
        --sleep  the number of seconds between beacons
    """

proc writeVersion*() =
    ## Writes the agent version.
    ##
    echo """Nicodemus

    Version: 0.0.1
    """
