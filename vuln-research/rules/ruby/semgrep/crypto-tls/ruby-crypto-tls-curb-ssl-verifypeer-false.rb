# Fixture for the Curl::Easy ssl_verify_peer disable rule.

def fetch(url)
  curl = Curl::Easy.new(url)
  # ruleid: ruby-crypto-tls-curb-ssl-verifypeer-false
  curl.ssl_verify_peer = false
  curl.perform
  curl.body_str
end

def fetch_secure(url)
  curl = Curl::Easy.new(url)
  # ok: ruby-crypto-tls-curb-ssl-verifypeer-false
  curl.ssl_verify_peer = true
  curl.perform
  curl.body_str
end
