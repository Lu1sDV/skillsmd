# Fixture exercising interpolated select expressions.

def projected(expr)
  # ruleid: ruby-sql-injection-select-interp
  Report.select("id, #{expr} AS computed")
end

def safe_projected
  # ok: ruby-sql-injection-select-interp
  Report.select(:id, :name)
end
