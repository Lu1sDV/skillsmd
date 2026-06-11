# Fixture for the Net::HTTP.get_response destination check.

def probe(target)
  # ruleid: ruby-ssrf-net-http-get-response
  resp = Net::HTTP.get_response(URI.parse("https://#{target}/status"))
  resp.body
end

def probe_fixed
  # ok: ruby-ssrf-net-http-get-response
  Net::HTTP.get_response(URI.parse("https://status.example.com/ok"))
end
