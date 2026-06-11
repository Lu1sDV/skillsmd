# Fixture for the Haml engine rule.
# Templates built from user input are flagged; a static template is safe.

def render(params)
  # ruleid: ruby-code-injection-haml-engine
  Haml::Engine.new(params[:tpl]).render(Object.new)
end

def render_interp(name)
  # ruleid: ruby-code-injection-haml-engine
  Haml::Engine.new("%p= #{name}").render(Object.new)
end

def safe_render
  # ok: ruby-code-injection-haml-engine
  Haml::Engine.new("%p= @name").render(Object.new)
end
