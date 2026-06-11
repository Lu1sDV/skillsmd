# Fixture for the IO.readlines pipe-path detector.

def lines_of(name)
  # ruleid: ruby-command-injection-io-readlines-pipe
  IO.readlines("#{name}")
end

def lines_of_safe(name)
  # ok: ruby-command-injection-io-readlines-pipe
  File.readlines("/data/#{name}.log")
end
