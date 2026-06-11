# Fixture for the ERB result rule.
# Templates built from user data are flagged; a static template is safe.

def render(params)
  # ruleid: ruby-code-injection-erb-result
  ERB.new(params[:template]).result(binding)
end

def render_interp(name)
  # ruleid: ruby-code-injection-erb-result
  ERB.new("Hello <%= #{name} %>").result(binding)
end

def safe_render
  # ok: ruby-code-injection-erb-result
  ERB.new("Hello <%= @name %>").result(binding)
end
