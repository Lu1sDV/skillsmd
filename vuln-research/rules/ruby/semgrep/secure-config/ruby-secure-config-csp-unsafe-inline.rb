# Fixture for the CSP unsafe-inline script source rule.

Rails.application.config.content_security_policy do |policy|
  # ruleid: ruby-secure-config-csp-unsafe-inline
  policy.script_src :self, :unsafe_inline
end

Rails.application.config.content_security_policy do |policy|
  # ok: ruby-secure-config-csp-unsafe-inline
  policy.script_src :self
end
