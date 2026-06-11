# Fixture: parsing the RFC 7239 Forwarded header versus using a pinned proxy contract.

class ForwardedParser
  def origin(request)
    # ruleid: ruby-http-parsing-env-forwarded-header-raw
    request.env["HTTP_FORWARDED"].to_s[/for=([^;]+)/, 1]
  end

  def trusted_origin(request)
    # ok: ruby-http-parsing-env-forwarded-header-raw
    request.remote_ip
  end
end
