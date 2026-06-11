# Fixture for the Faraday ssl verify disable rule.

def conn(url)
  # ruleid: ruby-crypto-tls-faraday-ssl-verify-false
  Faraday.new(url: url, ssl: { verify: false })
end

def conn_secure(url)
  # ok: ruby-crypto-tls-faraday-ssl-verify-false
  Faraday.new(url: url, ssl: { ca_file: "/etc/ssl/certs/ca.pem" })
end
