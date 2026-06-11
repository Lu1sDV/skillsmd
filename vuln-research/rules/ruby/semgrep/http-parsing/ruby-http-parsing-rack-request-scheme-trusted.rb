# Fixture: trusting the forwarded scheme to skip a TLS redirect.

class Guard
  def secure?(request)
    # ruleid: ruby-http-parsing-rack-request-scheme-trusted
    request.scheme == "https"
  end

  def secure_by_config?
    # ok: ruby-http-parsing-rack-request-scheme-trusted
    Rails.application.config.force_ssl
  end
end
