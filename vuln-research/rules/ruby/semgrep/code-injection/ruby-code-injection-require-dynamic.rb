# Fixture for the dynamic require rule.
# Requiring a request-derived feature is flagged; a constant require is safe.

def load_driver(params)
  # ruleid: ruby-code-injection-require-dynamic
  require(params[:driver])
end

def load_local(name)
  # ruleid: ruby-code-injection-require-dynamic
  require_relative("ext/#{name}")
end

def safe_load
  # ok: ruby-code-injection-require-dynamic
  require("json")
end
