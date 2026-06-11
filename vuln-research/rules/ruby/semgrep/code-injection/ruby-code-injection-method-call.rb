# Fixture for the method().call rule.
# Looking up a method by request data and calling it is flagged; a literal is safe.

def invoke(params)
  # ruleid: ruby-code-injection-method-call
  method(params[:fn]).call
end

def invoke_on(obj, params)
  # ruleid: ruby-code-injection-method-call
  obj.method(params[:fn]).call(1)
end

def safe_invoke
  # ok: ruby-code-injection-method-call
  method(:refresh).call
end
