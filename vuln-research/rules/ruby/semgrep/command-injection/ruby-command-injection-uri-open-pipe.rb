# Fixture for the URI.open pipe-prefix detector.

def fetch_remote(target)
  # ruleid: ruby-command-injection-uri-open-pipe
  URI.open("#{target}").read
end

def fetch_remote_safe(path)
  # ok: ruby-command-injection-uri-open-pipe
  URI.open("https://api.example.com/v1/items").read
end
