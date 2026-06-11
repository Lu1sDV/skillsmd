# Fixture for the CSP unsafe-eval script source rule.

Rails.application.config.content_security_policy do |policy|
  # ruleid: ruby-secure-config-csp-unsafe-eval
  policy.script_src :self, :unsafe_eval
end

Rails.application.config.content_security_policy do |policy|
  # ok: ruby-secure-config-csp-unsafe-eval
  policy.script_src :self, :https
end
