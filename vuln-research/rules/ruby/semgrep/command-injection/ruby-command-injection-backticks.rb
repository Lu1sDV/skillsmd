# Fixture for the backtick command-literal detector.
# The dynamic backtick line should be flagged; the constant one stays clean.

def disk_usage(path)
  # ruleid: ruby-command-injection-backticks
  `du -sh #{path}`
end

def uptime_static
  # ok: ruby-command-injection-backticks
  `uptime`
end
