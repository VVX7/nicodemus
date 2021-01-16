#[
    Author: Roger Johnston, Twitter: @VV_X_7
    License: GNU AGPLv3
]#
import strutils

proc hexToSeqByte*(hexString: string): seq[byte] =
    ## Converts a hex string to a sequence of bytes.
    ## 
    for i in countup(0, len(hexString)-2, 2):
        result.add((fromHex[byte](hexString[i] & hexString[i+1])))

proc seqByteToHex*(byteSeq: seq[byte]): string =
    ## Converts a hex string to a sequence of bytes.
    ## 
    for i in byteSeq:
        result = result & toHex(i)
