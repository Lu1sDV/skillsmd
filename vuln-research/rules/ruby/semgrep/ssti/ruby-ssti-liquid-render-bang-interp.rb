# Fixture for Liquid parse-from-interpolation evaluated with render!.

def render_strict(topic)
  # ruleid: ruby-ssti-liquid-render-bang-interp
  Liquid::Template.parse("Topic: #{topic}").render!("x" => 1)
end

def render_strict_safe
  # ok: ruby-ssti-liquid-render-bang-interp
  Liquid::Template.parse("Topic: {{ topic }}").render!("topic" => "x")
end
