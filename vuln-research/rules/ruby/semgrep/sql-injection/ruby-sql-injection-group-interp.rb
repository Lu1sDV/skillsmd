# Fixture exercising interpolated group clauses.

def grouped(dim)
  # ruleid: ruby-sql-injection-group-interp
  Order.group("#{dim}").count
end

def safe_grouped
  # ok: ruby-sql-injection-group-interp
  Order.group(:status).count
end
