# Fixture exercising raw find_by_sql usage.

def lookup(term)
  # ruleid: ruby-sql-injection-find-by-sql
  User.find_by_sql("SELECT * FROM users WHERE name = '#{term}'")
end

def parameterized(term)
  # ok: ruby-sql-injection-find-by-sql
  User.find_by_sql(["SELECT * FROM users WHERE name = ?", term])
end
