import os
import strutils


type
    Executor = object
        os: string
        file: seq[string]
        executor: seq[string]

let windows = Executor(
    os: "windows",
    file: @["pwsh.exe", "powershell.exe", "cmd.exe"],
    executor: @["pwsh", "psh", "cmd"]
)

let linux = Executor(
    os: "linux",
    file: @["python3", "pwsh", "sh"],
    executor: @["python", "pwsh", "sh"]
)

let darwin = Executor(
    os: "darwin",
    file: @["python3", "pwsh", "sh", "osascript"],
    executor: @["python", "pwsh", "sh", "osa"]
)

let freebsd = Executor(
    os: "freebsd",
    file: @["python3", "sh"],
    executor: @["python", "sh"]
)

proc returnPlatform*(): string =
    ## Returns the host operating system.  On MacOS systems, Nim returns the value `macosx`
    ## but Operator expects `darwin`.
    let host = hostOS
    if host == "macosx" os host == "macos":
        result = "darwin"
    else:
        result = host

proc findExecutable(file: string): bool =
    ## Test if a path points to an executable file.
    ##
    let fileKind: set[PathComponent] = {pcFile, pcLinkToFile}
    let executePermissions: set[FilePermission] = {fpUserExec, fpGroupExec, fpOthersExec}

    try:
        var fileInfo = os.getFileInfo(file)
        if fileInfo.kind in fileKind:
            if executePermissions <= fileInfo.permissions:
                return true
    except OSError:
        return

proc envPathSplit(): seq[string] =
    ## Splits the environment variable PATH using OS path delimiter.
    ## 
    var path = string(getEnv("PATH"))
    when defined windows:
        result = split(path, ";")
    else:
        result = split(path, ":")

proc checkIfExecutorAvailable(file: string): bool =
    ## Searches for an executable in directories named in the environment variable PATH.
    ##
    # If the file name includes a slash we assume it is an ansolute or relative path.
    when defined windows:
        if "\\" in file:
            result = findExecutable(file)
            return result
    else:
        if "/" in file:
            result = findExecutable(file)
            return result
    
    var paths: seq[string] = envPathSplit()
    var path: string
    for dir in paths:
        if dir == "":
            path = "./"
        path = joinPath(dir, file)
        if findExecutable(path):
            result = true

proc determineExecutors*(): seq[string] =
    ## Searches for available execution engines.
    ## 
    ## The "keyword" executor is the fallback executor which executes commands via the Nim os library.
    var supportedExecutors: seq[Executor] = @[windows, linux, darwin, freebsd]
    result.add("keyword")

    for eachExecutor in supportedExecutors:
        if eachExecutor.os == returnPlatform():
            for f in eachExecutor.file:
                if checkIfExecutorAvailable(f):
                    result.add(f)
