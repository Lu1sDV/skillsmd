# Fixture exercising raw select_value / select_one / select_rows usage.

def tally(uid)
  # ruleid: ruby-sql-injection-select-value
  conn.select_value("SELECT count(*) FROM visits WHERE user_id = #{uid}")
end

def latest(uid)
  # ruleid: ruby-sql-injection-select-value
  conn.select_one("SELECT * FROM visits WHERE user_id = #{uid} LIMIT 1")
end

def static_tally
  # ok: ruby-sql-injection-select-value
  conn.select_value("SELECT count(*) FROM visits")
end
