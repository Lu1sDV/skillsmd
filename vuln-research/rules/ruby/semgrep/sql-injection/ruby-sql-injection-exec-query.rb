# Fixture exercising raw exec_query usage.

def rows_for(status)
  # ruleid: ruby-sql-injection-exec-query
  conn.exec_query("SELECT * FROM orders WHERE status = '#{status}'")
end

def bound_rows(status)
  # ok: ruby-sql-injection-exec-query
  conn.exec_query("SELECT * FROM orders WHERE status = $1", "q", [status])
end
