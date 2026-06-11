# Fixture exercising interpolated find_by conditions.

def locate(token)
  # ruleid: ruby-sql-injection-find-by-interp
  User.find_by("api_token = '#{token}'")
end

def safe_locate(token)
  # ok: ruby-sql-injection-find-by-interp
  User.find_by(api_token: token)
end
