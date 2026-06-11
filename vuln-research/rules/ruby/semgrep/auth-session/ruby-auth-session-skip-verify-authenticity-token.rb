# Fixture exercising the CSRF-token skip detector.
# Flagged lines disable the forgery check; the safe controller keeps it on.

class PaymentsController < ApplicationController
  # ruleid: ruby-auth-session-skip-verify-authenticity-token
  skip_before_action :verify_authenticity_token

  def create
  end
end

class WebhooksController < ApplicationController
  # ruleid: ruby-auth-session-skip-verify-authenticity-token
  skip_before_action :verify_authenticity_token, only: [:receive]
end

class SafeController < ApplicationController
  # ok: ruby-auth-session-skip-verify-authenticity-token
  before_action :authenticate_user!
end
