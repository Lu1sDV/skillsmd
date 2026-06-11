# Fixture: generating an absolute URL from the request host versus a config host.

class Notifier
  def link(request)
    # ruleid: ruby-http-parsing-url-for-host-from-request
    url_for(controller: "p", action: "show", host: request.host)
  end

  def safe_link
    # ok: ruby-http-parsing-url-for-host-from-request
    url_for(controller: "p", action: "show", host: ENV.fetch("APP_HOST"))
  end
end
