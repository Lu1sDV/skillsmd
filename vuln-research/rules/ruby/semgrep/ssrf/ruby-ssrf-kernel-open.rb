# Fixture for the bare Kernel#open URL check.

def legacy_fetch(resource)
  # ruleid: ruby-ssrf-kernel-open
  open("http://#{resource}/data", "r").read
end

def legacy_fixed
  # ok: ruby-ssrf-kernel-open
  open("http://static.example.com/data", "r").read
end
