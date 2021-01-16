# Nicodemus

Nicodemus is a cross-platform Nim implant for the Prelude Operator adversary emulation platform.  

It's a port of [Pneuma](https://github.com/preludeorg/pneuma) and intended as a reference implementation for those thinking about writing their own Operator agent in Nim. Where possible, Nicodemus' code closely resembles that of Pneuma.

## Getting started

Use `build.sh` to compile Nicodemus for the host OS and Windows build target.

Run the compiled agent to connect on the default TCP address.  For help use the `-h` command switch.

### Linux 

1. Install [Nim](https://nim-lang.org/install_unix.html).
2. Install [MinGW-w64 toolchain](https://nim-lang.org/install_unix.html).
   - `Ubuntu: apt install mingw-w64`
3. Compile agent for build targets.
   - `./build.sh`

### MacOS

1. Install [Nim](https://nim-lang.org/install_unix.html).
2. Install [MinGW-w64 toolchain](https://nim-lang.org/install_unix.html).
   - `OSX: brew install mingw-w64`
3. Compile agent for build targets.
   - `./build.sh`

## Cross-compiling

Nim cross-compiling is documented [here](https://nim-lang.org/docs/nimc.html#crossminuscompilation).

Check out this [Docker image for easy cross-compiling](https://github.com/chrisheller/docker-nim-cross).  You'll need to install any nimble packages required by this project first.

## Use without Operator

Nicodemus is a port of [Pneuma](https://github.com/preludeorg/pneuma) so it's meant to be used with Prelude Operator.  If you want to use a different C2 you'll need to structure messages so that Nicodemus understands.  See Pneuma [beacon documentation](https://github.com/preludeorg/pneuma#use-without-operator) for more detail.

### C2 Instruction

```
{
  ID: "067e99fb-f88f-49a8-aadc-b5cadf3438d4",
  ttp: "0b726950-11fc-4b15-a7d3-0d6e9cfdbeab",
  tactic: "discovery",
  Executor: "sh",
  Request: "whoami",
  Payload: "https://s3.amazonaws.com/operator.payloads/demo.exe",
}
```

### Agent Beacon

```
{
  "Name": "test",
  "Location": "/tmp/me.go"
  "Platform": "darwin",
  "Executors": ["sh"],
  "Range": "red",
  "Pwd": "/tmp",
  "Links": []
}
```

### Links

```
{
  "ID": "123",
  "Executor": "sh",
  "Payload: "",
  "Request": "whoami",
  "Response: "",
  "Status: 0,
  "Pid": 0
}
```

## Channel selection

Nicodemus currently supports TCP, UDP and HTTP. 

### TCP
`./main --contact=tcp --address=127.0.0.1 --port=2323`

### UDP
`./main --contact=udp --address=127.0.0.1 --port=4545`

### HTTP

`./main --contact=http --address=http://127.0.0.1 --port=3391`


## Coming soon


