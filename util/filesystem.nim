#[
    Author: Roger Johnston, Twitter: @VV_X_7
    License: GNU AGPLv3
]#
import streams
import httpclient


proc saveFile(data: Stream, path: string) =
    ## Saves an HTTP bodyStream to a file.
    ##
    var stream_bytes = data.readAll()
    writeFile(path, stream_bytes)
