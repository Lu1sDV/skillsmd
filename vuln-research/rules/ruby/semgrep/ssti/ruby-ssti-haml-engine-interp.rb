# Fixture for Haml engine built from an interpolated template body.

def render_card(title)
  # ruleid: ruby-ssti-haml-engine-interp
  Haml::Engine.new("%h1 #{title}").render
end

def render_card_safe
  # ok: ruby-ssti-haml-engine-interp
  Haml::Engine.new("%h1= title").render(Object.new, title: "x")
end
