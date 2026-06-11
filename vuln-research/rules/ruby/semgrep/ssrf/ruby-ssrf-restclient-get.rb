# Fixture for the RestClient.get destination check.

def relay(endpoint)
  # ruleid: ruby-ssrf-restclient-get
  RestClient.get("https://#{endpoint}/v1/info")
end

def relay_fixed
  # ok: ruby-ssrf-restclient-get
  RestClient.get("https://api.example.com/v1/info")
end
