# Fixture for the Open3.popen2e string-command detector.

def build(target)
  # ruleid: ruby-command-injection-open3-popen2e
  Open3.popen2e("make #{target}")
end

def build_safe(target)
  # ok: ruby-command-injection-open3-popen2e
  Open3.popen2e("make", target)
end
