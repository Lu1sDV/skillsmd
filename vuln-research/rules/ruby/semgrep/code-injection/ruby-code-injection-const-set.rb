# Fixture for the const_set rule.
# Defining a constant from request data is flagged; a literal name is safe.

def define(params)
  # ruleid: ruby-code-injection-const-set
  Object.const_set(params[:name], Class.new)
end

def define_bare(params)
  # ruleid: ruby-code-injection-const-set
  const_set(params[:c], 42)
end

def safe_define
  # ok: ruby-code-injection-const-set
  Object.const_set("Registered", true)
end
