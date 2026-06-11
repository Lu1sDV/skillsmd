# Fixture for the Open3.capture2 string-command detector.

def inspect_image(path)
  # ruleid: ruby-command-injection-open3-capture2
  Open3.capture2("identify #{path}")
end

def inspect_image_safe(path)
  # ok: ruby-command-injection-open3-capture2
  Open3.capture2("identify", path)
end
