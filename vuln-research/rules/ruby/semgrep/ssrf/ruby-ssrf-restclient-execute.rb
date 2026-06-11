# Fixture for the RestClient::Request.execute url check.

def low_level(host)
  # ruleid: ruby-ssrf-restclient-execute
  RestClient::Request.execute(method: :get, url: "https://#{host}/api", timeout: 5)
end

def low_level_fixed
  # ok: ruby-ssrf-restclient-execute
  RestClient::Request.execute(method: :get, url: "https://api.example.com/api", timeout: 5)
end
