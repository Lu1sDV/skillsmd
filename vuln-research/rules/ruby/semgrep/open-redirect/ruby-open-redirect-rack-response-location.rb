# Fixture for Rack-level Location header writes.

class RedirectMiddleware
  def call(params)
    res = Rack::Response.new
    # ruleid: ruby-open-redirect-rack-response-location
    res["Location"] = params["url"]
    res.status = 302
    res.finish
  end

  def explicit(params)
    res = Rack::Response.new
    # ruleid: ruby-open-redirect-rack-response-location
    res.set_header("Location", params["target"])
    res.finish
  end

  def safe(params)
    res = Rack::Response.new
    # ok: ruby-open-redirect-rack-response-location
    res["Location"] = "/login"
    res.finish
  end
end
