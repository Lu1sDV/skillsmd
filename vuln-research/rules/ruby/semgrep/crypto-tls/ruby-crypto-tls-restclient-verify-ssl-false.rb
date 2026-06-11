# Fixture for the RestClient verify_ssl disable rule.

def call_api(url, body)
  # ruleid: ruby-crypto-tls-restclient-verify-ssl-false
  RestClient::Request.execute(method: :post, url: url, payload: body, verify_ssl: false)
end

def call_api_secure(url, body)
  # ok: ruby-crypto-tls-restclient-verify-ssl-false
  RestClient::Request.execute(method: :post, url: url, payload: body, verify_ssl: OpenSSL::SSL::VERIFY_PEER)
end
