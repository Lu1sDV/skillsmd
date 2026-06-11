# Fixture exercising interpolated delete_all conditions.

def purge(state)
  # ruleid: ruby-sql-injection-delete-all-interp
  Session.delete_all("state = '#{state}'")
end

def purge_relation(state)
  # ok: ruby-sql-injection-delete-all-interp
  Session.where(state: state).delete_all
end
