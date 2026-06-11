# Fixture exercising raw count_by_sql usage.

def active_count(flag)
  # ruleid: ruby-sql-injection-count-by-sql
  User.count_by_sql("SELECT count(*) FROM users WHERE flag = '#{flag}'")
end

def total_count
  # ok: ruby-sql-injection-count-by-sql
  User.count_by_sql("SELECT count(*) FROM users")
end
