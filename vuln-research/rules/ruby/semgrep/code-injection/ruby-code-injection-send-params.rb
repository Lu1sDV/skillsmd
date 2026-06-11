# Fixture for the dynamic send rule.
# Dispatching on a request-supplied name is flagged; a literal name is safe.

def dispatch(obj, params)
  # ruleid: ruby-code-injection-send-params
  obj.send(params[:action])
end

def dispatch_alias(obj, params)
  # ruleid: ruby-code-injection-send-params
  obj.__send__(params[:m], 1, 2)
end

def safe_dispatch(obj)
  # ok: ruby-code-injection-send-params
  obj.send(:refresh)
end
