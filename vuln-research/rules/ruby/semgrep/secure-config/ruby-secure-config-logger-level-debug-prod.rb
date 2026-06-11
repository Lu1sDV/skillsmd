# Fixture for the verbose production log level rule.

Rails.application.configure do
  # ruleid: ruby-secure-config-logger-level-debug-prod
  config.log_level = :debug
end

Rails.application.configure do
  # ok: ruby-secure-config-logger-level-debug-prod
  config.log_level = :info
end
