# Fixture for the Open3.capture3 string-command detector.

def archive(dir)
  # ruleid: ruby-command-injection-open3-capture3
  Open3.capture3("tar czf out.tgz #{dir}")
end

def archive_safe(dir)
  # ok: ruby-command-injection-open3-capture3
  Open3.capture3("tar", "czf", "out.tgz", dir)
end
