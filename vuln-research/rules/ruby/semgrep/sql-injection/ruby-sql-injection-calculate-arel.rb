# Fixture exercising an aggregate over an interpolated Arel.sql fragment.

def total(expr)
  # ruleid: ruby-sql-injection-calculate-arel
  Order.sum(Arel.sql("#{expr}"))
end

def safe_total
  # ok: ruby-sql-injection-calculate-arel
  Order.sum(:total)
end
