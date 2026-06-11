# Fixture for the disabled HSTS ssl options rule.

Rails.application.configure do
  # ruleid: ruby-secure-config-ssl-options-hsts-disabled
  config.ssl_options = { hsts: false }
end

Rails.application.configure do
  # ok: ruby-secure-config-ssl-options-hsts-disabled
  config.ssl_options = { hsts: { expires: 1.year, subdomains: true } }
end
