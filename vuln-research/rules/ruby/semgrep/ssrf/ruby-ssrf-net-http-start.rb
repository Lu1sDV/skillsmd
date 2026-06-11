# Fixture for the Net::HTTP.start host check.

def connect(remote)
  # ruleid: ruby-ssrf-net-http-start
  Net::HTTP.start("#{remote}", 443, use_ssl: true) do |http|
    http.get("/")
  end
end

def connect_fixed
  # ok: ruby-ssrf-net-http-start
  Net::HTTP.start("api.example.com", 443, use_ssl: true) do |http|
    http.get("/")
  end
end
