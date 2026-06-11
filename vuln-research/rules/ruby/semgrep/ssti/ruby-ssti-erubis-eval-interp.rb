# Fixture for legacy Erubis engine compiled from an interpolated string.

def render_label(text)
  # ruleid: ruby-ssti-erubis-eval-interp
  Erubis::Eruby.new("Label: #{text}").result(binding)
end

def render_label_safe
  # ok: ruby-ssti-erubis-eval-interp
  Erubis::Eruby.new("Label: <%= text %>").result(binding)
end
