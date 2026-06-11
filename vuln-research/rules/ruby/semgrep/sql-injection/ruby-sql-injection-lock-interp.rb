# Fixture exercising interpolated lock clauses.

def locked(mode)
  # ruleid: ruby-sql-injection-lock-interp
  Account.lock("FOR #{mode}").find(1)
end

def safe_locked
  # ok: ruby-sql-injection-lock-interp
  Account.lock(true).find(1)
end
