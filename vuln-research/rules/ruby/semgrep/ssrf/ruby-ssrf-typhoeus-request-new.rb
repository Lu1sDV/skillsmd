# Fixture for the Typhoeus::Request.new destination check.

def build(host)
  # ruleid: ruby-ssrf-typhoeus-request-new
  req = Typhoeus::Request.new("https://#{host}/v2", method: :get)
  req.run
end

def build_fixed
  # ok: ruby-ssrf-typhoeus-request-new
  req = Typhoeus::Request.new("https://v2.example.com/v2", method: :get)
  req.run
end
