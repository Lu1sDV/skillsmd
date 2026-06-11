# Fixture for the HTTParty.get destination check.

def lookup(domain)
  # ruleid: ruby-ssrf-httparty-get
  HTTParty.get("https://#{domain}/whoami")
end

def lookup_fixed
  # ok: ruby-ssrf-httparty-get
  HTTParty.get("https://whoami.example.com/whoami")
end
