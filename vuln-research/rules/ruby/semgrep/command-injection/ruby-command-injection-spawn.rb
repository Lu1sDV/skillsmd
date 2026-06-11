# Fixture for the Kernel#spawn single-string detector.

def launch(job)
  # ruleid: ruby-command-injection-spawn
  spawn("worker --job #{job}")
end

def launch_safe(job)
  # ok: ruby-command-injection-spawn
  spawn("worker", "--job", job)
end
