# Fixture: building a link from the client Host header versus a fixed canonical host.

class MailerHelper
  def reset_link(request)
    # ruleid: ruby-http-parsing-rack-request-host-trusted
    "https://#{request.host}/reset"
  end

  def canonical_link
    # ok: ruby-http-parsing-rack-request-host-trusted
    "https://#{CANONICAL_HOST}/reset"
  end
end
