# Fixture for the binding eval rule.
# The dynamic-scope evaluations are flagged; the constant string is safe.

def in_scope(params)
  b = binding
  # ruleid: ruby-code-injection-binding-eval
  b.eval("#{params[:code]}")
end

def toplevel(params)
  # ruleid: ruby-code-injection-binding-eval
  TOPLEVEL_BINDING.eval("x = #{params[:val]}")
end

def safe_scope
  b = binding
  # ok: ruby-code-injection-binding-eval
  b.eval("@cache")
end
