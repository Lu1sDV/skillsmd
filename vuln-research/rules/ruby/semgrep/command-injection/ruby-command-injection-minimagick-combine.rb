# Fixture for the MiniMagick merged-option detector.

def resize(convert, geometry)
  # ruleid: ruby-command-injection-minimagick-combine
  convert.merge!(["-resize #{geometry}"])
end

def resize_safe(convert, geometry)
  # ok: ruby-command-injection-minimagick-combine
  convert.merge!(["-resize", geometry])
end
