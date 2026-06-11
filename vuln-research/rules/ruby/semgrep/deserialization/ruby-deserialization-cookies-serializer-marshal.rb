# Fixture for the cookies serializer rule.
# Flagged lines select Marshal/hybrid cookie serialization; safe line selects JSON.

Rails.application.configure do
  # ruleid: ruby-deserialization-cookies-serializer-marshal
  config.action_dispatch.cookies_serializer = :marshal

  # ruleid: ruby-deserialization-cookies-serializer-marshal
  config.action_dispatch.cookies_serializer = :hybrid

  # ok: ruby-deserialization-cookies-serializer-marshal
  config.action_dispatch.cookies_serializer = :json
end
