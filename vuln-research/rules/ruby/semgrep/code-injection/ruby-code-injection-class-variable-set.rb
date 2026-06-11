# Fixture for the class_variable_set rule.
# Setting a class variable named by request data is flagged; a literal is safe.

def configure(klass, params)
  # ruleid: ruby-code-injection-class-variable-set
  klass.class_variable_set(params[:cvar], params[:value])
end

def configure_self(params)
  # ruleid: ruby-code-injection-class-variable-set
  class_variable_set(params[:k], true)
end

def safe_configure(klass, value)
  # ok: ruby-code-injection-class-variable-set
  klass.class_variable_set(:@@limit, value)
end
