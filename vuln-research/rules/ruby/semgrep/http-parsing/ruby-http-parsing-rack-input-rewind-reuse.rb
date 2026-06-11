# Fixture: draining rack.input in middleware versus reading the rewindable body.

class BodyLogger
  def call(env)
    # ruleid: ruby-http-parsing-rack-input-rewind-reuse
    raw = env["rack.input"].read
    log(raw)
    @app.call(env)
  end

  def call_safe(env)
    request = Rack::Request.new(env)
    # ok: ruby-http-parsing-rack-input-rewind-reuse
    body = request.body.read
    request.body.rewind
    @app.call(env)
  end
end
