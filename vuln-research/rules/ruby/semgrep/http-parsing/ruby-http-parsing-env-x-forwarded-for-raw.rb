# Fixture: pulling the forwarded-for chain directly versus the framework remote IP.

class Geo
  def client_ip(request)
    # ruleid: ruby-http-parsing-env-x-forwarded-for-raw
    request.env["HTTP_X_FORWARDED_FOR"].to_s.split(",").first
  end

  def trusted_ip(request)
    # ok: ruby-http-parsing-env-x-forwarded-for-raw
    request.remote_ip
  end
end
