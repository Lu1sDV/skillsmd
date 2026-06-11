# Fixture for an Excon request with interpolated host option.

def hit(host)
  # ruleid: ruby-ssrf-excon-request
  Excon.get(host: "#{host}", path: "/status")
end

def hit_fixed
  # ok: ruby-ssrf-excon-request
  Excon.get(host: "status.example.com", path: "/status")
end
