# Fixture for the %x command-literal detector.

def grep_logs(term)
  # ruleid: ruby-command-injection-percent-x
  %x(grep #{term} /var/log/app.log)
end

def list_static
  # ok: ruby-command-injection-percent-x
  %x(ls /tmp)
end
