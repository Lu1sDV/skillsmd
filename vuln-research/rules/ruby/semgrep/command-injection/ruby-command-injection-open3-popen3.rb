# Fixture for the Open3.popen3 string-command detector.

def convert(src)
  # ruleid: ruby-command-injection-open3-popen3
  Open3.popen3("convert #{src} out.png")
end

def convert_safe(src)
  # ok: ruby-command-injection-open3-popen3
  Open3.popen3("convert", src, "out.png")
end
