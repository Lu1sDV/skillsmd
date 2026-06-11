# Fixture for the disabled deep munge rule.

Rails.application.configure do
  # ruleid: ruby-secure-config-perform-deep-munge-disabled
  config.action_dispatch.perform_deep_munge = false
end

Rails.application.configure do
  # ok: ruby-secure-config-perform-deep-munge-disabled
  config.action_dispatch.perform_deep_munge = true
end
