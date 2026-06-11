# Fixture for the overly broad YAML permitted classes rule.

Rails.application.configure do
  # ruleid: ruby-secure-config-yaml-permitted-classes-object
  config.active_record.yaml_column_permitted_classes = [Symbol, Object]
end

Rails.application.configure do
  # ok: ruby-secure-config-yaml-permitted-classes-object
  config.active_record.yaml_column_permitted_classes = [Symbol, Date, Time]
end
