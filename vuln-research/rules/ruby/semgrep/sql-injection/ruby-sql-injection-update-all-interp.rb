# Fixture exercising interpolated update_all assignments.

def bump(role)
  # ruleid: ruby-sql-injection-update-all-interp
  User.where(active: true).update_all("role = '#{role}'")
end

def safe_bump(role)
  # ok: ruby-sql-injection-update-all-interp
  User.where(active: true).update_all(role: role)
end
