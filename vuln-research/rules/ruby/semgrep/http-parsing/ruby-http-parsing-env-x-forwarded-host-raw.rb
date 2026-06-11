# Fixture: composing a redirect target from the forwarded host versus a fixed host.

class RedirectBuilder
  def back_to(request)
    # ruleid: ruby-http-parsing-env-x-forwarded-host-raw
    "https://#{request.env['HTTP_X_FORWARDED_HOST']}/home"
  end

  def home
    # ok: ruby-http-parsing-env-x-forwarded-host-raw
    "https://#{CANONICAL_HOST}/home"
  end
end
