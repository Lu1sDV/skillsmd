# Fixture for the Rake sh single-string detector.

def deploy(env)
  # ruleid: ruby-command-injection-rake-sh
  sh("cap deploy #{env}")
end

def deploy_safe(env)
  # ok: ruby-command-injection-rake-sh
  sh("cap", "deploy", env)
end
