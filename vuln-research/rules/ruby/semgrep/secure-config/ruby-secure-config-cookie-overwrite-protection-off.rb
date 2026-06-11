# Fixture for the legacy cookie encryption rule.

Rails.application.configure do
  # ruleid: ruby-secure-config-cookie-overwrite-protection-off
  config.action_dispatch.use_authenticated_cookie_encryption = false
end

Rails.application.configure do
  # ok: ruby-secure-config-cookie-overwrite-protection-off
  config.action_dispatch.use_authenticated_cookie_encryption = true
end
