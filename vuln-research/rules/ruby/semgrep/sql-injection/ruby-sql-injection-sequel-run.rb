# Fixture exercising Sequel run / execute with raw interpolated SQL.

def drop_temp(name)
  # ruleid: ruby-sql-injection-sequel-run
  DB.run("DROP TABLE tmp_#{name}")
end

def static_run
  # ok: ruby-sql-injection-sequel-run
  DB.run("ANALYZE")
end
