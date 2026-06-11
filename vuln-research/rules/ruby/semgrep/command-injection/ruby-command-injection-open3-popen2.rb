# Fixture for the Open3.popen2 string-command detector.

def transcode(file)
  # ruleid: ruby-command-injection-open3-popen2
  Open3.popen2("ffmpeg -i #{file} out.mp4")
end

def transcode_safe(file)
  # ok: ruby-command-injection-open3-popen2
  Open3.popen2("ffmpeg", "-i", file, "out.mp4")
end
