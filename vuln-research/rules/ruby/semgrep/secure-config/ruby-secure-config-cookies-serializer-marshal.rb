# Fixture for the unsafe cookie serializer rule.

Rails.application.configure do
  # ruleid: ruby-secure-config-cookies-serializer-marshal
  config.action_dispatch.cookies_serializer = :marshal
end

Rails.application.configure do
  # ok: ruby-secure-config-cookies-serializer-marshal
  config.action_dispatch.cookies_serializer = :json
end
