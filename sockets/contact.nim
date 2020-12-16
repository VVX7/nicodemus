import random
import strformat
import strutils
import os
from times import getTime, toUnix, nanosecond


# Contact defines functions for communicating with the server.
type
    Contact* = object
        protocol*: string

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
