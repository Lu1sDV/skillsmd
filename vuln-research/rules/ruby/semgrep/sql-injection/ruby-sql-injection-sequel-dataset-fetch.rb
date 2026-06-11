# Fixture exercising Sequel fetch with raw interpolated SQL.

def fetch_user(uid)
  # ruleid: ruby-sql-injection-sequel-dataset-fetch
  DB.fetch("SELECT * FROM users WHERE id = #{uid}").all
end

def bound_fetch(uid)
  # ok: ruby-sql-injection-sequel-dataset-fetch
  DB.fetch("SELECT * FROM users WHERE id = ?", uid).all
end
