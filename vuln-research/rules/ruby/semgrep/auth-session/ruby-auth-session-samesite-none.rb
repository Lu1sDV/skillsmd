# Fixture for the SameSite=None cookie-protection detector.

module App
  class Application < Rails::Application
    # ruleid: ruby-auth-session-samesite-none
    config.action_dispatch.cookies_same_site_protection = :none
  end
end

module Strict
  class Application < Rails::Application
    # ok: ruby-auth-session-samesite-none
    config.action_dispatch.cookies_same_site_protection = :strict
  end
end
