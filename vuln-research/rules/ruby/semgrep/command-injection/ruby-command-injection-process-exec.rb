# Fixture for the Process.exec string-command detector.

def takeover(cmd)
  # ruleid: ruby-command-injection-process-exec
  Process.exec("env #{cmd}")
end

def takeover_safe(cmd)
  # ok: ruby-command-injection-process-exec
  Process.exec("env", cmd)
end
