# Fixture exercising interpolated from clauses.

def from_tenant(schema)
  # ruleid: ruby-sql-injection-from-interp
  Record.from("#{schema}.records")
end

def from_fixed
  # ok: ruby-sql-injection-from-interp
  Record.from("records")
end
