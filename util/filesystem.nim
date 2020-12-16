import streams
import httpclient

var client = newHttpClient()
var response = request(client, "http://example.com")

proc saveFile(data: Stream, path: string) =
    var stream_bytes = data.readAll()
    writeFile(path, stream_bytes)

saveFile(response.bodyStream, "text.html")
