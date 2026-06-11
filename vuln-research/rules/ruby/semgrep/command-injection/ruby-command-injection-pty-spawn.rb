# Fixture for the PTY.spawn string-command detector.

def interactive(shell_arg)
  # ruleid: ruby-command-injection-pty-spawn
  PTY.spawn("login #{shell_arg}") { |r, w, pid| }
end

def interactive_safe(shell_arg)
  # ok: ruby-command-injection-pty-spawn
  PTY.spawn("login", shell_arg) { |r, w, pid| }
end
