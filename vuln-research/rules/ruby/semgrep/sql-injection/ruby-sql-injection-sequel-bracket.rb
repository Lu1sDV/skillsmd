# Fixture exercising Sequel bracket accessor with raw interpolated SQL.

def find_row(uid)
  # ruleid: ruby-sql-injection-sequel-bracket
  DB["SELECT * FROM accounts WHERE id = #{uid}"].first
end

def bound_row(uid)
  # ok: ruby-sql-injection-sequel-bracket
  DB["SELECT * FROM accounts WHERE id = ?", uid].first
end
