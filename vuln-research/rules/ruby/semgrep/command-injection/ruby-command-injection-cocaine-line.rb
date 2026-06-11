# Fixture for the Cocaine::CommandLine interpolated-template detector.

def optimize(quality)
  # ruleid: ruby-command-injection-cocaine-line
  Cocaine::CommandLine.new("jpegoptim -m#{quality} in.jpg").run
end

def optimize_safe(quality)
  # ok: ruby-command-injection-cocaine-line
  Cocaine::CommandLine.new("jpegoptim", "-m:q in.jpg").run(q: quality)
end
