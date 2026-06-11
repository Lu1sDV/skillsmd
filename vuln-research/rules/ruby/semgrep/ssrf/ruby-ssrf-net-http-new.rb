# Fixture for the Net::HTTP.new host check.

def client_for(host)
  # ruleid: ruby-ssrf-net-http-new
  http = Net::HTTP.new("#{host}", 80)
  http.get("/")
end

def client_fixed
  # ok: ruby-ssrf-net-http-new
  http = Net::HTTP.new("internal.example.com", 80)
  http.get("/")
end
