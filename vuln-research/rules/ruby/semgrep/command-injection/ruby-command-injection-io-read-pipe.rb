# Fixture for the IO.read pipe-path detector.

def load_report(name)
  # ruleid: ruby-command-injection-io-read-pipe
  IO.read("#{name}")
end

def load_report_safe(name)
  # ok: ruby-command-injection-io-read-pipe
  File.read("/reports/#{name}.txt")
end
