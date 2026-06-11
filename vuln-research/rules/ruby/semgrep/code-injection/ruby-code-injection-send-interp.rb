# Fixture for the interpolated-send rule.
# A dynamically built method name is flagged; a fixed string name is safe.

def dispatch(obj, type)
  # ruleid: ruby-code-injection-send-interp
  obj.send("process_#{type}")
end

def dispatch_alias(obj, suffix)
  # ruleid: ruby-code-injection-send-interp
  obj.__send__("handle_#{suffix}", 1)
end

def safe_dispatch(obj)
  # ok: ruby-code-injection-send-interp
  obj.send("process_default")
end
