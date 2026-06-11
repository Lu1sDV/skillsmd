# Fixture for a Mechanize agent GET with interpolated URL.

def crawl(agent, host)
  # ruleid: ruby-ssrf-mechanize-get
  agent.get("https://#{host}/page")
end

def crawl_fixed(agent)
  # ok: ruby-ssrf-mechanize-get
  agent.get("https://pages.example.com/page")
end
