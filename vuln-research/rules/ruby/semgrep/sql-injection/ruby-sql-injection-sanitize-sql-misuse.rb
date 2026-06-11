# Fixture exercising misuse of the sanitize_sql helper.

def cond(name)
  # ruleid: ruby-sql-injection-sanitize-sql-misuse
  User.sanitize_sql("name = '#{name}'")
end

def safe_cond(name)
  # ok: ruby-sql-injection-sanitize-sql-misuse
  User.sanitize_sql(["name = ?", name])
end
