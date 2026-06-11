# Fixture for Slim template compiled from an interpolated string.

def render_banner(msg)
  # ruleid: ruby-ssti-slim-template-interp
  Slim::Template.new { "p #{msg}" }.render
end

def render_banner_file
  # ok: ruby-ssti-slim-template-interp
  Slim::Template.new("views/banner.slim").render(scope, msg: "x")
end
