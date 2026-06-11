# Fixture covering concat of pre-marked safe content.

def emit(name)
  # ruleid: ruby-xss-concat-html-safe
  concat("<b>#{name}</b>".html_safe)
end

def emit_raw(name)
  # ruleid: ruby-xss-concat-html-safe
  concat(raw("<i>#{name}</i>"))
end

def emit_escaped(name)
  # ok: ruby-xss-concat-html-safe
  concat("<b>#{name}</b>")
end
