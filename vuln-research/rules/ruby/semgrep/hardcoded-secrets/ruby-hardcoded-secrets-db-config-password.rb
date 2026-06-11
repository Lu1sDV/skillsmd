# Fixture for hardcoded database connection password.
# Flagged calls inline a literal password; safe call pulls it from the environment.

class DbBootstrap
  def connect_inline
    # ruleid: ruby-hardcoded-secrets-db-config-password
    ActiveRecord::Base.establish_connection(adapter: "postgresql", host: "db", password: "Sup3rSecretDbPass")
  end

  def connect_safe
    # ok: ruby-hardcoded-secrets-db-config-password
    ActiveRecord::Base.establish_connection(adapter: "postgresql", host: "db", password: ENV["DB_PASSWORD"])
  end
end
