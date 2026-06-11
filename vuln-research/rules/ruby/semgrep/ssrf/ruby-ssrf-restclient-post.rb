# Fixture for the RestClient.post destination check.

def push(endpoint, payload)
  # ruleid: ruby-ssrf-restclient-post
  RestClient.post("https://#{endpoint}/ingest", payload)
end

def push_fixed(payload)
  # ok: ruby-ssrf-restclient-post
  RestClient.post("https://ingest.example.com/ingest", payload)
end
