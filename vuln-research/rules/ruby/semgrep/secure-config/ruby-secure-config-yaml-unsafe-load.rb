# Fixture for the unsafe YAML column loading rule.

Rails.application.configure do
  # ruleid: ruby-secure-config-yaml-unsafe-load
  config.active_record.use_yaml_unsafe_load = true
end

Rails.application.configure do
  # ok: ruby-secure-config-yaml-unsafe-load
  config.active_record.use_yaml_unsafe_load = false
end
