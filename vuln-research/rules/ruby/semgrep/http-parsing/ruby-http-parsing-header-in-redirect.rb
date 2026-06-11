# Fixture: redirecting back to a client-supplied Referer versus a known route.

class BackController
  def go
    # ruleid: ruby-http-parsing-header-in-redirect
    redirect_to request.referer
  end

  def go_safe
    # ok: ruby-http-parsing-header-in-redirect
    redirect_to root_path
  end
end
