# Fixture for the blanket CSRF skip rule.

class WebhookController < ApplicationController
  # ruleid: ruby-secure-config-skip-csrf-verification
  skip_before_action :verify_authenticity_token
end

class ApiController < ApplicationController
  # ok: ruby-secure-config-skip-csrf-verification
  skip_before_action :verify_authenticity_token, only: [:create]
end
