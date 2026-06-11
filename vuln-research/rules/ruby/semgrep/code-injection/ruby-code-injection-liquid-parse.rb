# Fixture for the Liquid parse rule.
# Parsing user-supplied template source is flagged; a literal template is safe.

def render(params)
  # ruleid: ruby-code-injection-liquid-parse
  Liquid::Template.parse(params[:body]).render("user" => current_user)
end

def render_interp(snippet)
  # ruleid: ruby-code-injection-liquid-parse
  Liquid::Template.parse("Hi {{ #{snippet} }}")
end

def safe_render
  # ok: ruby-code-injection-liquid-parse
  Liquid::Template.parse("Hi {{ user.name }}")
end
