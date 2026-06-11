# Fixture for the disabled HTTPS enforcement rule.

Rails.application.configure do
  # ruleid: ruby-secure-config-force-ssl-disabled
  config.force_ssl = false
end

Rails.application.configure do
  # ok: ruby-secure-config-force-ssl-disabled
  config.force_ssl = true
end
