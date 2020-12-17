# Nicodemus

Nicodemus is a Nim RAT for the Prelude Operator adversary emulation platform.  

It's a port of [Pneuma](https://github.com/preludeorg/pneuma) and intended as a reference implementation for those thinking about writing their own Prelude agent. As much as possible, Nicodemus' code closely resembles that of Pneuma

## Getting started

Install Nim and Nimble.

Install Nicodemus deps:
- `nimcrypto`

Compile the agent and run it.  Use `-h` for help.

## Channel selection

Nicodemus currently supports TCP, UDP and HTTP.

### TCP
`./main --contact=tcp --address=127.0.0.1 --port=2323`

### UDP
`./main --contact=udp --address=127.0.0.1 --port=4545`

### HTTP

`./main --contact=http --address=http://127.0.0.1 --port=3391`


## Cross-compilation

Nim cross-compiles to all kinds of [fun stuff](https://nim-lang.org/docs/nimc.html#crossminuscompilation-for-nintendo-switch).

Assuming you're compiling from a Linux host the following commands show to build the agent.

### Linux

`nim c "./main.nim"`

### Windows

Install `mingw-w64` toolchain.

`nim c --cpu:amd64 --app:console -d:mingw  "./main.nim"`

## Coming soon


