import uri
import strutils
import strformat
import random
import os
import net
import logging
from times import getTime, toUnix, nanosecond


var logger = newConsoleLogger()

# Contact describes networking for an upstream listener.
type
    Contact* = object
        protocol*: string
        address*: string
        port*: int

# Instruction defines TTP execution metadata.
type
    Instruction* = object
        ID*: string
        ttp*: string
        tactic*: string
        Executor*: string
        Payload*: string
        Request*: string
        Response*: string
        Status*: int
        Pid*: int

# Beacon defines agent beacon metadata.
type
    Beacon* = object
        Name*: string
        Location*: string
        Platform*: string
        Executors*: seq[string]
        Range*: string
        Pwd*: string
        Links*: seq[Instruction]

# HTTP payload file data.
type
    HTTPPayload* = object
        body*: string
        filename*: string
        error*: int


proc verifyAddress*(contact: Contact): bool =
    ## Checks if the address is valid for the specified protocol.
    ##
    ##
    if contact.protocol.startsWith("http"):
        let host = parseUri(contact.address)
        if host.scheme == "" or host.hostname == "":
            logger.log(lvlFatal, fmt"{contact.address} is an invalid URL for HTTP/S beacons.")
        else:
            return true
    else:
        if isIpAddress(contact.address):
            if 0 < contact.port and contact.port < 65535:
                return true

proc parseUriBase*(address: string): string =
    ## Returns the last element of a path.
    ## 
    ## Port of https://golang.org/pkg/path/filepath/#Base
    if address == "":
        return "."
    # Strip trailing slashes.
    var base: string = address
    while base.endsWith("/"):
        base = base[0..^2]
    # Find the last element.
    var path = base.split("/")
    base = path[^1]
    if base == "":
        result = "/"
    else:
        result = base

proc jitterSleep*(sleep: int, beaconType: string) =
    ## Sleeps for approximately `sleep` seconds.
    ## 
    let now = getTime()
    var r = initRand(now.nanosecond)
    var min: int = int(float64(sleep) * 0.90)
    var max: int = int(float64(sleep) * 1.10)
    var randomSleep = r.rand(max - min + 1) + min
    echo fmt("[{beaconType}] Next beacon going out in {randomSleep} seconds")
    sleep(randomSleep * 1000)
