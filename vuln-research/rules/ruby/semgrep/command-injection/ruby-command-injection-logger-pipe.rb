# Fixture for the Logger.new pipe-device detector.

def build_logger(target)
  # ruleid: ruby-command-injection-logger-pipe
  Logger.new("#{target}", 10)
end

def build_logger_safe
  # ok: ruby-command-injection-logger-pipe
  Logger.new($stdout)
end
