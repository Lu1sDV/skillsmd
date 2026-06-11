# Fixture: reflecting the client Origin into a response header versus a fixed value.

class CorsController
  def reflect
    # ruleid: ruby-http-parsing-response-header-from-request
    response.headers["Access-Control-Allow-Origin"] = request.headers["Origin"]
  end

  def fixed
    # ok: ruby-http-parsing-response-header-from-request
    response.headers["Access-Control-Allow-Origin"] = "https://app.example.com"
  end
end
