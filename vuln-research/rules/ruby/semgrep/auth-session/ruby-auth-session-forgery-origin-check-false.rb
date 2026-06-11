# Fixture for the forgery origin-check toggle detector.

module App
  class Application < Rails::Application
    # ruleid: ruby-auth-session-forgery-origin-check-false
    config.action_controller.forgery_protection_origin_check = false
  end
end

module Safe
  class Application < Rails::Application
    # ok: ruby-auth-session-forgery-origin-check-false
    config.action_controller.forgery_protection_origin_check = true
  end
end
