# Fixture for the Process.spawn single-string detector.

def run_async(target)
  # ruleid: ruby-command-injection-process-spawn
  Process.spawn("scan #{target}")
end

def run_async_safe(target)
  # ok: ruby-command-injection-process-spawn
  Process.spawn("scan", target)
end
