# Fixture for the IO.foreach pipe-path detector.

def each_line(name)
  # ruleid: ruby-command-injection-io-foreach-pipe
  IO.foreach("#{name}") { |line| puts line }
end

def each_line_safe(name)
  # ok: ruby-command-injection-io-foreach-pipe
  File.foreach("/var/data/#{name}") { |line| puts line }
end
