# Fixture for the Kernel#open pipe-prefix detector.

def fetch(name)
  # ruleid: ruby-command-injection-open-pipe
  open("#{name}", "r").read
end

def fetch_file(name)
  # ok: ruby-command-injection-open-pipe
  File.open("/data/#{name}", "r").read
end
