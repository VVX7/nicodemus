#[
    Author: Roger Johnston, Twitter: @VV_X_7
    License: GNU AGPLv3
]#
import strformat
import nimcrypto/sysrand
import nimcrypto/rijndael
import nimcrypto/bcmode
import logging
from sequtils import concat, repeat
from ../util/config import encryptionKey


var logger = newConsoleLogger()

# Conversion taken from
# https://github.com/nim-lang/Nim/issues/14810
proc toString*(buf: seq[byte]): string = move cast[ptr string](buf.unsafeAddr)[]
proc toByteSeq*(data: string): seq[byte] = move cast[ptr seq[byte]](data.unsafeAddr)[]

proc generateIV(length: int = 16): seq[byte] =
    ## Returns a sequence of random bytes using the system's random number generator.
    ## 
    ## https://cheatfate.github.io/nimcrypto/nimcrypto/sysrand.html#randomBytes,pointer,int
    var buff = newSeq[byte](length)
    discard randomBytes(bytes = buff)
    result = buff

proc pad(data: seq[byte], blockSize: int = 16): seq[byte] =
    ## Applies pkcs7 padding.
    ## 
    ## https://github.com/Legrandin/pycryptodome/blob/master/lib/Crypto/Util/Padding.py
    let paddingLength: int = blockSize - len(data) mod blockSize
    let padding = repeat(byte(paddingLength), paddingLength)
    result = concat(data, padding)

proc unpad(data: seq[byte], blockSize: int = 16): seq[byte] = 
    ## Removes pkcs7 padding.
    ## 
    ## https://github.com/Legrandin/pycryptodome/blob/master/lib/Crypto/Util/Padding.py
    let paddedDataLength: int = len(data)
    if paddedDataLength == 0:
        logger.log(lvlWarn, "Data cannot be zero-length.")
        result = data
    elif (paddedDataLength mod blockSize) != 0:
        logger.log(lvlWarn, "Data isn't alignment to blockSize.")
        result = data
    else:
        let paddingLength = ord(data[^1])
        if paddingLength < 1:
            logger.log(lvlWarn, "Padding is incorrect: paddingLength < 1")
            result = data
        elif paddingLength > paddedDataLength:
            logger.log(lvlWarn, "Padding is incorrect: paddingLength > paddedDataLength")
            result = data
        elif paddingLength > blockSize:
            logger.log(lvlWarn, fmt"Padding is incorrect:  {paddingLength} > blockSize")
            result = data
        elif data[^int(paddingLength) .. ^1] != repeat(byte(paddingLength), paddingLength):
            logger.log(lvlWarn, "PKCS#7 padding is incorrect.")
            result = data
        else:
            result = data[0 .. ^(int(paddingLength)+1)]

proc encrypt*(plainText: seq[byte], agentKey: string): seq[byte] =
    ## Encrypts data using AES-256 CBC.
    ##
    ## https://github.com/cheatfate/nimcrypto/blob/master/examples/cbc.nim
    var ctx: CBC[aes256]
    let key: seq[byte] = toByteSeq(agentKey)
    let iv: seq[byte] = generateIV(length = 16)
    # Initialize CBC[aes256] context.
    ctx.init(key, iv)
    # Pad plainText to blockSize 16.
    let paddedPlainText: seq[byte] = pad(plainText, 16)
    let lengthPlainText: int = len(paddedPlainText)
    # Encrypt the plainText.
    var encrypted = newSeq[byte](lengthPlainText)
    ctx.encrypt(paddedPlainText, encrypted)
    let cipherText = concat(iv, encrypted)
    ctx.clear()
    result = cipherText

proc encrypt*(plainText: string, agentKey: string): seq[byte] =
    ## Encrypts data using AES-256 CBC.
    ##
    ## Overload `encrypt` that performs automatic seq[byte] conversion.
    result = encrypt(toByteSeq(plainText), agentKey)

proc decrypt*(cipherText: seq[byte], agentKey: string): seq[byte] =
    ## Decrypts data using AES-256 CBC.
    ## 
    ## https://github.com/cheatfate/nimcrypto/blob/master/examples/cbc.nim
    var ctx: CBC[aes256]
    let key: seq[byte] = toByteSeq(agentKey)
    let iv = cipherText[0 .. 15]
    let encrypted = cipherText[16..^1]
    # Initialize CBC[aes256] context.
    ctx.init(key, iv)
    # Decrypt cipherText.
    let lengthCipherText: int = len(encrypted)
    var plainText  = newSeq[byte](lengthCipherText)
    ctx.decrypt(encrypted, plainText)
    ctx.clear()
    # Unpad the plainText.
    result = unpad(data = plainText, blockSize = 16)

proc decrypt*(cipherText: string, agentKey: string): seq[byte] =
    ## Decrypts data using AES-256 CBC.
    ## 
    ## Overload `decrypt` that performs automatic seq[byte] conversion.
    result = decrypt(toByteSeq(cipherText), agentKey)
