# Fixture for the remove_const rule.
# Removing a constant named by request data is flagged; a literal is safe.

def purge(params)
  # ruleid: ruby-code-injection-remove-const
  Object.send(:remove_const, params[:name])
end

def purge_direct(params)
  # ruleid: ruby-code-injection-remove-const
  Registry.remove_const(params[:c])
end

def safe_purge
  # ok: ruby-code-injection-remove-const
  Object.send(:remove_const, :TempClass)
end
