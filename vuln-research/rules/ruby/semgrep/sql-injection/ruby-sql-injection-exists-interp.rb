# Fixture exercising interpolated exists? conditions.

def present?(email)
  # ruleid: ruby-sql-injection-exists-interp
  User.exists?("email = '#{email}'")
end

def safe_present?(email)
  # ok: ruby-sql-injection-exists-interp
  User.exists?(email: email)
end
