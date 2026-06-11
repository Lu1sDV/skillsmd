# Fixture for Liquid template parsed from an interpolated source string.

def render_notice(subject)
  # ruleid: ruby-ssti-liquid-parse-interp
  Liquid::Template.parse("Notice about #{subject}").render
end

def render_notice_safe
  # ok: ruby-ssti-liquid-parse-interp
  Liquid::Template.parse("Notice about {{ subject }}").render("subject" => "x")
end
