# Fixture: trusting the forwarded protocol header versus enforcing TLS by config.

class TlsCheck
  def https?(request)
    # ruleid: ruby-http-parsing-env-x-forwarded-proto-raw
    request.env["HTTP_X_FORWARDED_PROTO"] == "https"
  end

  def enforced?
    # ok: ruby-http-parsing-env-x-forwarded-proto-raw
    Rails.application.config.force_ssl
  end
end
