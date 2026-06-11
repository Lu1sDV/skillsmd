# Fixture for the verbose error page rule.

Rails.application.configure do
  # ruleid: ruby-secure-config-consider-all-requests-local
  config.consider_all_requests_local = true
end

Rails.application.configure do
  # ok: ruby-secure-config-consider-all-requests-local
  config.consider_all_requests_local = false
end
