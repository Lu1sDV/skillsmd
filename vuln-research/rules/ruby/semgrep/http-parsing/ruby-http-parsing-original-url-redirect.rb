# Fixture: redirecting to a host-derived absolute URL versus a relative path.

class SessionsController
  def after_login
    # ruleid: ruby-http-parsing-original-url-redirect
    redirect_to request.original_url
  end

  def safe_after_login
    # ok: ruby-http-parsing-original-url-redirect
    redirect_to "/dashboard"
  end
end
