# Fixture: gating an admin path on a spoofable forwarded client IP.

class AdminGate
  def allow?(request)
    allowed_ips = ["10.0.0.5"]
    # ruleid: ruby-http-parsing-rack-request-ip-trusted
    allowed_ips.include?(request.ip)
  end

  def allow_by_token?(request)
    # ok: ruby-http-parsing-rack-request-ip-trusted
    valid_token?(request.headers["X-Admin-Token"])
  end
end
