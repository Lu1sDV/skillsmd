# Fixture for the http.rb HTTP.get destination check.

def get_it(host)
  # ruleid: ruby-ssrf-httprb-get
  HTTP.get("https://#{host}/ping")
end

def get_with_headers(host, token)
  # ruleid: ruby-ssrf-httprb-get
  HTTP.headers(authorization: token).get("https://#{host}/ping")
end

def get_fixed
  # ok: ruby-ssrf-httprb-get
  HTTP.get("https://ping.example.com/ping")
end
