# Fixture for the Action Cable origin protection rule.

Rails.application.configure do
  # ruleid: ruby-secure-config-action-cable-allow-all-origins
  config.action_cable.disable_request_forgery_protection = true
end

Rails.application.configure do
  # ok: ruby-secure-config-action-cable-allow-all-origins
  config.action_cable.allowed_request_origins = ["https://app.example.com"]
end
