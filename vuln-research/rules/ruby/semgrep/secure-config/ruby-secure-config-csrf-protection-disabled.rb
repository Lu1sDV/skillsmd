# Fixture for the weakened CSRF protection rule.

class ApplicationController < ActionController::Base
  # ruleid: ruby-secure-config-csrf-protection-disabled
  protect_from_forgery with: :null_session
end

class SecureController < ActionController::Base
  # ok: ruby-secure-config-csrf-protection-disabled
  protect_from_forgery with: :exception
end
