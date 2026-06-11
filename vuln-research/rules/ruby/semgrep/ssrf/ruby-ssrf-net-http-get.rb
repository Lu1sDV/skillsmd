# Fixture for the Net::HTTP.get destination check.
# Interpolated targets should be flagged; the constant target should not.

def fetch_profile(user_host)
  # ruleid: ruby-ssrf-net-http-get
  Net::HTTP.get(URI("https://#{user_host}/profile"))
end

def fetch_raw(host)
  # ruleid: ruby-ssrf-net-http-get
  Net::HTTP.get("http://#{host}/data")
end

def fetch_fixed
  # ok: ruby-ssrf-net-http-get
  Net::HTTP.get(URI("https://api.internal.example.com/health"))
end
