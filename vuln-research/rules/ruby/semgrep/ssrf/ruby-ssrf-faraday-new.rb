# Fixture for the Faraday.new base-URL check.

def connection(host)
  # ruleid: ruby-ssrf-faraday-new
  Faraday.new("https://#{host}")
end

def connection_kw(host)
  # ruleid: ruby-ssrf-faraday-new
  Faraday.new(url: "https://#{host}/api")
end

def connection_fixed
  # ok: ruby-ssrf-faraday-new
  Faraday.new("https://api.example.com")
end
