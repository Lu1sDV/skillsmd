# Fixture for the HTTParty verify disable rule.

def fetch(url)
  # ruleid: ruby-crypto-tls-httparty-verify-false
  HTTParty.get(url, verify: false)
end

def fetch_secure(url)
  # ok: ruby-crypto-tls-httparty-verify-false
  HTTParty.get(url, ssl_ca_file: "/etc/ssl/certs/ca.pem")
end
