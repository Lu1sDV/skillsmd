# Fixture for the assume_ssl misconfiguration rule.

Rails.application.configure do
  # ruleid: ruby-secure-config-assume-ssl-without-force
  config.assume_ssl = true
end

Rails.application.configure do
  # ok: ruby-secure-config-assume-ssl-without-force
  config.force_ssl = true
end
