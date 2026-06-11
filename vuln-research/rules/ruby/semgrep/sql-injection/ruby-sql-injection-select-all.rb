# Fixture exercising raw select_all usage.

def report(group)
  # ruleid: ruby-sql-injection-select-all
  ActiveRecord::Base.connection.select_all("SELECT * FROM logs WHERE grp = '#{group}'")
end

def static_report
  # ok: ruby-sql-injection-select-all
  ActiveRecord::Base.connection.select_all("SELECT count(*) FROM logs")
end
