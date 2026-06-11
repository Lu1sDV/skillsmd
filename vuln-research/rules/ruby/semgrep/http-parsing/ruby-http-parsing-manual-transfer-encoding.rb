# Fixture: branching on the raw Transfer-Encoding header versus reading parsed body.

class Framing
  def chunked?(request)
    # ruleid: ruby-http-parsing-manual-transfer-encoding
    request.env["HTTP_TRANSFER_ENCODING"].to_s.include?("chunked")
  end

  def body(request)
    # ok: ruby-http-parsing-manual-transfer-encoding
    request.body.read
  end
end
