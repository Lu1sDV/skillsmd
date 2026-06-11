# Fixture for the disabled host authorization rule.

Rails.application.configure do
  # ruleid: ruby-secure-config-host-authorization-disabled
  config.hosts.clear
end

Rails.application.configure do
  # ok: ruby-secure-config-host-authorization-disabled
  config.hosts << "app.example.com"
end
