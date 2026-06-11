# Fixture covering tag helper attribute with raw value.

def tooltip(text)
  # ruleid: ruby-xss-tag-helper-raw-attr
  tag.span("hi", title: raw(text))
end

def box(blob)
  # ruleid: ruby-xss-tag-helper-raw-attr
  tag.div("x", data: raw(blob))
end

def safe_tooltip(text)
  # ok: ruby-xss-tag-helper-raw-attr
  tag.span("hi", title: text)
end
