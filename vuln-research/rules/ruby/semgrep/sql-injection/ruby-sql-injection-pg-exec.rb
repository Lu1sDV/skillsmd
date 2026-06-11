# Fixture exercising the pg driver exec with interpolated SQL.

def pg_lookup(conn, uid)
  # ruleid: ruby-sql-injection-pg-exec
  conn.exec("SELECT * FROM users WHERE id = #{uid}")
end

def pg_bound(conn, uid)
  # ok: ruby-sql-injection-pg-exec
  conn.exec_params("SELECT * FROM users WHERE id = $1", [uid])
end
