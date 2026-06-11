# Fixture for the TCPSocket.new / TCPSocket.open host check.

def raw_connect(host, port)
  # ruleid: ruby-ssrf-tcpsocket-new
  TCPSocket.new("#{host}", port)
end

def raw_connect_fixed(port)
  # ok: ruby-ssrf-tcpsocket-new
  TCPSocket.new("queue.internal.example.com", port)
end
