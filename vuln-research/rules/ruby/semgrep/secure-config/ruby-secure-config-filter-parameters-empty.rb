# Fixture for the empty parameter filter rule.

Rails.application.configure do
  # ruleid: ruby-secure-config-filter-parameters-empty
  config.filter_parameters = []
end

Rails.application.configure do
  # ok: ruby-secure-config-filter-parameters-empty
  config.filter_parameters = [:password, :token, :secret]
end
