# Fixture exercising raw connection.execute usage.

def purge(table)
  # ruleid: ruby-sql-injection-connection-execute
  ActiveRecord::Base.connection.execute("DELETE FROM #{table}")
end

def static_exec
  # ok: ruby-sql-injection-connection-execute
  ActiveRecord::Base.connection.execute("VACUUM")
end
