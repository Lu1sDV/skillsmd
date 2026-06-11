# Fixture for the CSP wildcard default source rule.

Rails.application.config.content_security_policy do |policy|
  # ruleid: ruby-secure-config-csp-wildcard-default-src
  policy.default_src "*"
end

Rails.application.config.content_security_policy do |policy|
  # ok: ruby-secure-config-csp-wildcard-default-src
  policy.default_src :self
end
