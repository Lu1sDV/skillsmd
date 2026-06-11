# Fixture exercising interpolated joins clauses.

def with_join(table)
  # ruleid: ruby-sql-injection-joins-interp
  User.joins("INNER JOIN #{table} ON #{table}.user_id = users.id")
end

def assoc_join
  # ok: ruby-sql-injection-joins-interp
  User.joins(:posts)
end
