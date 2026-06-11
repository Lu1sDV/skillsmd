# Fixture for the session cookie missing Secure flag rule.

# ruleid: ruby-secure-config-session-cookie-not-secure
Rails.application.config.session_store :cookie_store, key: "_app", secure: false

# ok: ruby-secure-config-session-cookie-not-secure
Rails.application.config.session_store :cookie_store, key: "_app", secure: true
