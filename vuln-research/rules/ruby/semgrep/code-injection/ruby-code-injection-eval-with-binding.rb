# Fixture for the eval-with-binding rule.
# Eval of tainted source in a scope is flagged; a constant string is safe.

def console(params)
  # ruleid: ruby-code-injection-eval-with-binding
  eval("#{params[:cmd]}", binding, __FILE__, __LINE__)
end

def console_var(params)
  # ruleid: ruby-code-injection-eval-with-binding
  eval(params[:expr], binding)
end

def safe_console
  # ok: ruby-code-injection-eval-with-binding
  eval("@count + 1", binding, __FILE__, __LINE__)
end
