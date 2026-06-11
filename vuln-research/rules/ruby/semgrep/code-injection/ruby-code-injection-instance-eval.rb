# Fixture for the instance_eval rule.
# Interpolated source string is flagged; the literal string form is safe.

def configure(obj, params)
  # ruleid: ruby-code-injection-instance-eval
  obj.instance_eval("def dyn; #{params[:body]}; end")
end

def patch(params)
  # ruleid: ruby-code-injection-instance-eval
  instance_eval("@x = #{params[:v]}")
end

def safe_configure(obj)
  # ok: ruby-code-injection-instance-eval
  obj.instance_eval("@ready = true")
end
