# Fixture for the session-cookie HttpOnly detector.

# ruleid: ruby-auth-session-session-cookie-httponly-false
Rails.application.config.session_store :cookie_store, key: "_app", httponly: false

# ok: ruby-auth-session-session-cookie-httponly-false
Rails.application.config.session_store :cookie_store, key: "_app", httponly: true
