# Fixture for the Excon.new base-URL check.

def conn(host)
  # ruleid: ruby-ssrf-excon-new
  Excon.new("https://#{host}")
end

def conn_fixed
  # ok: ruby-ssrf-excon-new
  Excon.new("https://api.example.com")
end
