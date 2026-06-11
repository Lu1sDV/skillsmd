# Fixture: directly driving the WEBrick request parser over a raw client socket.
# Flagged calls re-parse untrusted bytes; the safe path delegates to the server.

require "webrick"

def handle(sock)
  req = WEBrick::HTTPRequest.new(WEBrick::Config::HTTP)
  # ruleid: ruby-http-parsing-webrick-parse-raw-socket
  req.parse(sock)
  req
end

def via_server(server, sock)
  # ok: ruby-http-parsing-webrick-parse-raw-socket
  server.run(sock)
end
