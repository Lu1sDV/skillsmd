# Fixture for the open-uri ssl_verify_mode disable rule.

require "open-uri"

def download(url)
  # ruleid: ruby-crypto-tls-openuri-verify-none
  URI.open(url, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).read
end

def download_secure(url)
  # ok: ruby-crypto-tls-openuri-verify-none
  URI.open(url, ssl_verify_mode: OpenSSL::SSL::VERIFY_PEER).read
end
