import os
import osproc
import strutils
import strformat
import logging
import strtabs
import streams


type
    CommandExecution* = object
        bites*: TaintedString
        status*: int
        pid*: int

var logger = newConsoleLogger()

proc changeDirectory(target: string): CommandExecution =
    ## Change the current working directory to target.
    ## 
    setCurrentDir(target)
    result = CommandExecution(bites: target)

proc catFile(target: string): CommandExecution =
    ## Opens the target file and reads it. `readFile` calls `readAll` and closes the file afterward.
    ## 
    let file: TaintedString = readFile(target)
    result = CommandExecution(bites: file)

proc cpFile(src: string, dest: string): CommandExecution =
    ## Copies a file from `src` to `dst` while preserving file permissions.
    ## 
    copyFileWithPermissions(src, dest)
    result = CommandExecution(bites: "")

proc getEnvs(): CommandExecution =
    ## Returns environment variables.
    ## 
    var output: string
    for k, v in envPairs():
        output = output & k & "=" & v & "\n"
    result = CommandExecution(bites: output)

proc execute(executable: string, command: seq[string]): CommandExecution =
    ## `osproc.execProcess` clone.
    ##
    ## `process` returned by `startProcess` provides pid and handle data.
    let env: StringTableRef = nil
    let options: set[ProcessOption] = {poStdErrToStdOut, poUsePath}
    var process = startProcess(executable, workingDir = "", args = command, env = env, options = options)
    var outp = outputStream(process)
    var outString = TaintedString""
    var line: string
    while true:
        # `osproc.execProcess` copypasta
        if outp.readLine(line):
            outString.string.add(line)
            outString.string.add("\n")
        elif not running(process): break
    result = CommandExecution(bites: outString, pid: processID(process))
    close(process)

proc runExecutor(executor: string, command: string): CommandExecution =
    ## Executes a process.
    ## 
    when defined windows:
        if executor == "cmd":
            result = execute(executable = "cmd.exe", command = @["/c", command])
        else:
            result = execute(executable = "powershell.exe", command = @["-ExecutionPolicy", "Bypass", "-C", command])
    else:
        if executor == "python":
            result = execute(executable = "python", command = @["-c", command])
        else:
            result = execute(executable = "sh", command = @["-c", command])

proc runCommand*(executor: string, message: string): CommandExecution =
    ## Executes `message` using the `executor` engine.
    ## 
    if message.startsWith("cd "):
        let pieces: seq[TaintedString] = message.split("cd ")
        let bites: TaintedString = pieces[1]
        result = changeDirectory(target=bites)
    elif executor == "keyword":
        try:
            # Call keyword commands
            if message.startsWith("cat "):
                let pieces: seq[TaintedString] = message.split("cat ")
                let bites: TaintedString = pieces[1]
                result = catFile(target=bites)
            elif message == "env":
                result = getEnvs()
            else:
                result = CommandExecution(bites: "Unknown command", status: 1)
        except:
            let exception = getCurrentException()
            let exceptionMsg = getCurrentExceptionMsg()
            logger.log(lvlWarn, fmt"[Warning] Exception occured in command '{message}'. Error: '{exceptionMsg}'. See: {repr(exception)}")
            result = CommandExecution(bites: exceptionMsg, status: 1)
    else:
        try:
            logger.log(lvlInfo, "Running instruction")
            result = runExecutor(executor = executor, command = message)
        except:
            let exception = getCurrentException()
            let exceptionMsg = getCurrentExceptionMsg()
            logger.log(lvlWarn, fmt"[Warning] Exception occured in command '{message}'. Error: '{exceptionMsg}'. See: {repr(exception)}")
            result = CommandExecution(bites: exceptionMsg, status: 1)
