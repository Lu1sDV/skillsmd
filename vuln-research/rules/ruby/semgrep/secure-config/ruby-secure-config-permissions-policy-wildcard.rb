# Fixture for the over-permissive Permissions-Policy rule.

Rails.application.config.permissions_policy do |policy|
  # ruleid: ruby-secure-config-permissions-policy-wildcard
  policy.camera :all
end

Rails.application.config.permissions_policy do |policy|
  # ok: ruby-secure-config-permissions-policy-wildcard
  policy.camera :self
end
