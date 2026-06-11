# Fixture exercising interpolated where.not conditions.

def excluding(role)
  # ruleid: ruby-sql-injection-where-not-interp
  User.where.not("role = '#{role}'")
end

def safe_excluding(role)
  # ok: ruby-sql-injection-where-not-interp
  User.where.not(role: role)
end
