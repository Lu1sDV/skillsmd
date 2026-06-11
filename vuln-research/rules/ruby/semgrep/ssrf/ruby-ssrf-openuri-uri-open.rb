# Fixture for the URI.open (OpenURI) destination check.

def slurp(url_host)
  # ruleid: ruby-ssrf-openuri-uri-open
  URI.open("https://#{url_host}/feed.xml").read
end

def slurp_fixed
  # ok: ruby-ssrf-openuri-uri-open
  URI.open("https://feeds.example.com/feed.xml").read
end
