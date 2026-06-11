# Fixture exercising interpolated having clauses.

def big_groups(threshold)
  # ruleid: ruby-sql-injection-having-interp
  Order.group(:status).having("sum(total) > #{threshold}")
end

def bound_groups(threshold)
  # ok: ruby-sql-injection-having-interp
  Order.group(:status).having("sum(total) > ?", threshold)
end
