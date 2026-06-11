# Fixture for the public_send rule.
# Tainted method names are flagged; a constant method name is safe.

def call_it(obj, params)
  # ruleid: ruby-code-injection-public-send
  obj.public_send(params[:method])
end

def call_interp(obj, suffix)
  # ruleid: ruby-code-injection-public-send
  obj.public_send("get_#{suffix}")
end

def safe_call(obj)
  # ok: ruby-code-injection-public-send
  obj.public_send("status")
end
