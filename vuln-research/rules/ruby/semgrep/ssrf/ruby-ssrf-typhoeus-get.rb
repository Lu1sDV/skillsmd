# Fixture for the Typhoeus.get destination check.

def fetch(host)
  # ruleid: ruby-ssrf-typhoeus-get
  Typhoeus.get("https://#{host}/data", followlocation: true)
end

def fetch_fixed
  # ok: ruby-ssrf-typhoeus-get
  Typhoeus.get("https://data.example.com/data", followlocation: true)
end
