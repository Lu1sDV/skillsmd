# Fixture: reading the raw Host env entry versus the validated request host.

class Links
  def absolute(request, path)
    # ruleid: ruby-http-parsing-env-http-host-raw
    host = request.env["HTTP_HOST"]
    "https://#{host}#{path}"
  end

  def safe_absolute(path)
    # ok: ruby-http-parsing-env-http-host-raw
    "https://#{ALLOWED_HOST}#{path}"
  end
end
