# Fixture: throttling on the forwarded IP versus on an authenticated account id.

Rack::Attack.throttle("req/ip", limit: 100, period: 60) do |req|
  # ruleid: ruby-http-parsing-remote-ip-throttle
  req.ip
end

Rack::Attack.throttle("req/acct", limit: 100, period: 60) do |req|
  # ok: ruby-http-parsing-remote-ip-throttle
  req.env["warden"].user&.id
end
