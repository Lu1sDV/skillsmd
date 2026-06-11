# Fixture for the constantize rule.
# Constantizing request data is flagged; a literal string is safe.

def model_for(params)
  # ruleid: ruby-code-injection-constantize
  params[:model].constantize
end

def model_safe_variant(params)
  # ruleid: ruby-code-injection-constantize
  params[:model].safe_constantize
end

def fixed_model
  # ok: ruby-code-injection-constantize
  "User".constantize
end
