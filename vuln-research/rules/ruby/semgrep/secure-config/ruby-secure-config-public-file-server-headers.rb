# Fixture for the open static asset CORS rule.

Rails.application.configure do
  # ruleid: ruby-secure-config-public-file-server-headers
  config.public_file_server.headers = { "Access-Control-Allow-Origin" => "*" }
end

Rails.application.configure do
  # ok: ruby-secure-config-public-file-server-headers
  config.public_file_server.headers = { "Cache-Control" => "public, max-age=3600" }
end
