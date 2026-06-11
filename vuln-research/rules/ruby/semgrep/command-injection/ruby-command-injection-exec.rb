# Fixture for the Kernel#exec single-string detector.

def replace_with(tool)
  # ruleid: ruby-command-injection-exec
  exec("/usr/bin/#{tool} --run")
end

def replace_kernel(tool)
  # ruleid: ruby-command-injection-exec
  Kernel.exec("run #{tool}")
end

def exec_argv(tool)
  # ok: ruby-command-injection-exec
  exec("runner", tool)
end
