# Fixture for the Terrapin::CommandLine interpolated-template detector.

def thumbnail(size)
  # ruleid: ruby-command-injection-terrapin-line
  Terrapin::CommandLine.new("convert in.png -resize #{size} out.png").run
end

def thumbnail_safe(size)
  # ok: ruby-command-injection-terrapin-line
  Terrapin::CommandLine.new("convert", "in.png -resize :size out.png").run(size: size)
end
