# Fixture for the const_get rule.
# Resolving a request-supplied constant name is flagged; a literal is safe.

def resolve(params)
  # ruleid: ruby-code-injection-const-get
  Object.const_get(params[:klass])
end

def resolve_bare(params)
  # ruleid: ruby-code-injection-const-get
  const_get(params[:type])
end

def safe_resolve
  # ok: ruby-code-injection-const-get
  Object.const_get("User")
end
