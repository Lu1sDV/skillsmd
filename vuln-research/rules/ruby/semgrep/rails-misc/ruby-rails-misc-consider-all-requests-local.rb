# Fixture for verbose error page enabled.

Rails.application.configure do
  # ruleid: ruby-rails-misc-consider-all-requests-local
  config.consider_all_requests_local = true

  # ok: ruby-rails-misc-consider-all-requests-local
  config.consider_all_requests_local = false
end
