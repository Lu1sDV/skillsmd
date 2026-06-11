# Fixture for the Slim template rule.
# Slim source from user input is flagged; a literal template is safe.

def render(params)
  # ruleid: ruby-code-injection-slim-template
  Slim::Template.new { params[:tpl] }.render(scope)
end

def render_arg(params)
  # ruleid: ruby-code-injection-slim-template
  Slim::Template.new(params[:path]).render(scope)
end

def safe_render
  # ok: ruby-code-injection-slim-template
  Slim::Template.new("p= @name").render(scope)
end
