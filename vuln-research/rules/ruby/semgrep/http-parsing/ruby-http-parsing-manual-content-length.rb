# Fixture: reading the body by the client-declared length versus the parsed body.

class RawBody
  def read(request)
    io = request.body
    # ruleid: ruby-http-parsing-manual-content-length
    io.read(request.env["CONTENT_LENGTH"].to_i)
  end

  def read_parsed(request)
    # ok: ruby-http-parsing-manual-content-length
    request.body.read
  end
end
