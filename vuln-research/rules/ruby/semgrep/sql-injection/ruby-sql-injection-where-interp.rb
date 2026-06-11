# Fixture exercising interpolated where conditions.

def by_name(name)
  # ruleid: ruby-sql-injection-where-interp
  User.where("name = '#{name}'")
end

def bound_name(name)
  # ok: ruby-sql-injection-where-interp
  User.where("name = ?", name)
end

def hash_name(name)
  # ok: ruby-sql-injection-where-interp
  User.where(name: name)
end
