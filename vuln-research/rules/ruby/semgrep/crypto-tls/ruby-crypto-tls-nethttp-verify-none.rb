# Fixture for the Net::HTTP verify_mode disable rule.

require "net/https"

def fetch(uri)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  # ruleid: ruby-crypto-tls-nethttp-verify-none
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  http.get(uri.request_uri)
end

def fetch_secure(uri)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  # ok: ruby-crypto-tls-nethttp-verify-none
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  http.get(uri.request_uri)
end
