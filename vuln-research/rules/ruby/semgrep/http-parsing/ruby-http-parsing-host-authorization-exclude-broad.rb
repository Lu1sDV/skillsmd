# Fixture: excluding all requests from host checks versus only a health endpoint.

Rails.application.configure do
  # ruleid: ruby-http-parsing-host-authorization-exclude-broad
  config.host_authorization = { exclude: ->(request) { true } }
end

Rails.application.configure do
  # ok: ruby-http-parsing-host-authorization-exclude-broad
  config.host_authorization = { exclude: ->(request) { request.path == "/healthz" } }
end
