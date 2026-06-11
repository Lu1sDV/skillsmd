# Fixture for the Typhoeus ssl_verifypeer disable rule.

def fetch(url)
  # ruleid: ruby-crypto-tls-typhoeus-ssl-verifypeer-false
  Typhoeus.get(url, ssl_verifypeer: false)
end

def fetch_secure(url)
  # ok: ruby-crypto-tls-typhoeus-ssl-verifypeer-false
  Typhoeus.get(url, cainfo: "/etc/ssl/certs/ca.pem")
end
