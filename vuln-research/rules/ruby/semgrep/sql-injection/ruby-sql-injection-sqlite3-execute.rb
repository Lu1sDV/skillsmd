# Fixture exercising the sqlite3 driver execute with interpolated SQL.

def lite_lookup(db, name)
  # ruleid: ruby-sql-injection-sqlite3-execute
  db.execute("SELECT * FROM users WHERE name = '#{name}'")
end

def lite_bound(db, name)
  # ok: ruby-sql-injection-sqlite3-execute
  db.execute("SELECT * FROM users WHERE name = ?", [name])
end
