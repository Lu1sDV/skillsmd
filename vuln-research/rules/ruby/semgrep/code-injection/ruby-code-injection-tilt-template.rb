# Fixture for the Tilt template rule.
# Tilt dispatch on user-controlled path/source is flagged; a literal path is safe.

def render(params)
  # ruleid: ruby-code-injection-tilt-template
  Tilt.new(params[:template]).render(self)
end

def render_interp(name)
  # ruleid: ruby-code-injection-tilt-template
  Tilt.new("views/#{name}.erb").render(self)
end

def safe_render
  # ok: ruby-code-injection-tilt-template
  Tilt.new("views/index.erb").render(self)
end
