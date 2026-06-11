# Fixture for disabled CSRF protection.

class PaymentsController < ApplicationController
  # ruleid: ruby-rails-misc-skip-forgery-protection
  skip_forgery_protection

  def charge
    process_payment
  end
end

class WebhooksController < ApplicationController
  # ruleid: ruby-rails-misc-skip-forgery-protection
  skip_before_action :verify_authenticity_token, only: [:receive]

  def receive
    handle_webhook
  end
end

class AccountController < ApplicationController
  # ok: ruby-rails-misc-skip-forgery-protection
  protect_from_forgery with: :exception

  def update
    save_account
  end
end
