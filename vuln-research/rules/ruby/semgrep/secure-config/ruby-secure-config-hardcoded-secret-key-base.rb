# Fixture for the hardcoded secret_key_base rule.

Rails.application.configure do
  # ruleid: ruby-secure-config-hardcoded-secret-key-base
  config.secret_key_base = "a3f9c1e0deadbeefcafef00dba5eba11a3f9c1e0deadbeef"
end

Rails.application.configure do
  # ok: ruby-secure-config-hardcoded-secret-key-base
  config.secret_key_base = ENV.fetch("SECRET_KEY_BASE")
end
