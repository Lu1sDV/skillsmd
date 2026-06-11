# Fixture for the Thor::Actions#run shell-helper detector.

def scaffold(name)
  # ruleid: ruby-command-injection-thor-run
  run("rails g model #{name}", verbose: false)
end

def scaffold_safe(name)
  # ok: ruby-command-injection-thor-run
  run(Shellwords.escape(name), verbose: false)
end
