# Fixture for the Socket.tcp host check.

def open_socket(host)
  # ruleid: ruby-ssrf-socket-tcp
  Socket.tcp("#{host}", 6379)
end

def open_socket_fixed
  # ok: ruby-ssrf-socket-tcp
  Socket.tcp("cache.internal.example.com", 6379)
end
