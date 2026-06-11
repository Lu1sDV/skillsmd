# Fixture for the global forgery-protection toggle detector.

module App
  class Application < Rails::Application
    # ruleid: ruby-auth-session-allow-forgery-protection-false
    config.action_controller.allow_forgery_protection = false
  end
end

module Prod
  class Application < Rails::Application
    # ok: ruby-auth-session-allow-forgery-protection-false
    config.action_controller.allow_forgery_protection = true
  end
end
