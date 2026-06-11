# Fixture for the instance_exec rule.
# Forwarding request-controlled args into the block is flagged; a constant is safe.

def apply(obj, params)
  # ruleid: ruby-code-injection-instance-exec
  obj.instance_exec(params[:scope]) { |s| send(s) }
end

def apply_req(obj, request)
  # ruleid: ruby-code-injection-instance-exec
  obj.instance_exec(request.path) { |p| @p = p }
end

def safe_apply(obj)
  # ok: ruby-code-injection-instance-exec
  obj.instance_exec(:ready) { |s| @state = s }
end
