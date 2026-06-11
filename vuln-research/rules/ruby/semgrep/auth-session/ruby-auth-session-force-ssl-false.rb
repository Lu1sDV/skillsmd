# Fixture for the force_ssl-disabled detector.

module App
  class Application < Rails::Application
    # ruleid: ruby-auth-session-force-ssl-false
    config.force_ssl = false
  end
end

module Prod
  class Application < Rails::Application
    # ok: ruby-auth-session-force-ssl-false
    config.force_ssl = true
  end
end
