# Fixture for the Curl.get destination check.

def pull(host)
  # ruleid: ruby-ssrf-curl-get
  Curl.get("https://#{host}/object")
end

def pull_fixed
  # ok: ruby-ssrf-curl-get
  Curl.get("https://object.example.com/object")
end
