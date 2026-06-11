# Fixture for the Excon ssl_verify_peer disable rule.

def client(url)
  # ruleid: ruby-crypto-tls-excon-verify-peer-false
  Excon.new(url, ssl_verify_peer: false)
end

def client_secure(url)
  # ok: ruby-crypto-tls-excon-verify-peer-false
  Excon.new(url, ssl_ca_file: "/etc/ssl/certs/ca.pem")
end
