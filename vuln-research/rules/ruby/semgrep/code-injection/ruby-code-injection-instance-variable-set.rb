# Fixture for the instance_variable_set rule.
# Setting an ivar named by request data is flagged; a literal name is safe.

def assign(obj, params)
  # ruleid: ruby-code-injection-instance-variable-set
  obj.instance_variable_set(params[:field], params[:value])
end

def assign_self(params)
  # ruleid: ruby-code-injection-instance-variable-set
  instance_variable_set(params[:k], 1)
end

def safe_assign(obj, value)
  # ok: ruby-code-injection-instance-variable-set
  obj.instance_variable_set(:@name, value)
end
