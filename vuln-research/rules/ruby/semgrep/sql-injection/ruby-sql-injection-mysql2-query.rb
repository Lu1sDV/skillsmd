# Fixture exercising the mysql2 client query with interpolated SQL.

def my_lookup(client, name)
  # ruleid: ruby-sql-injection-mysql2-query
  client.query("SELECT * FROM users WHERE name = '#{name}'")
end

def my_static(client)
  # ok: ruby-sql-injection-mysql2-query
  client.query("SELECT version()")
end
