# Fixture for the disabled TLS verification rule.

def fetch(uri)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  # ruleid: ruby-secure-config-disable-ssl-on-net-http
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  http.get(uri.path)
end

def fetch_secure(uri)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  # ok: ruby-secure-config-disable-ssl-on-net-http
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  http.get(uri.path)
end
