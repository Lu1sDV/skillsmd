# Fixture: relaying the raw WEBrick body and headers upstream versus a rebuilt request.

require "net/http"

class Proxy
  def forward(req, uri)
    # ruleid: ruby-http-parsing-webrick-body-passthrough
    Net::HTTP.post(uri, req.body, req.header)
  end

  def forward_clean(req, uri)
    payload = sanitize(req.body)
    # ok: ruby-http-parsing-webrick-body-passthrough
    Net::HTTP.post(uri, payload, { "Content-Type" => "application/json" })
  end
end
