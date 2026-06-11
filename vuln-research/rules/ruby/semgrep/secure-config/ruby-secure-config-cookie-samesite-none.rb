# Fixture for the SameSite none session cookie rule.

# ruleid: ruby-secure-config-cookie-samesite-none
Rails.application.config.session_store :cookie_store, key: "_app", same_site: :none

# ok: ruby-secure-config-cookie-samesite-none
Rails.application.config.session_store :cookie_store, key: "_app", same_site: :lax
