# Fixture for the session cookie missing HttpOnly rule.

# ruleid: ruby-secure-config-session-cookie-not-httponly
Rails.application.config.session_store :cookie_store, key: "_app", httponly: false

# ok: ruby-secure-config-session-cookie-not-httponly
Rails.application.config.session_store :cookie_store, key: "_app", httponly: true
