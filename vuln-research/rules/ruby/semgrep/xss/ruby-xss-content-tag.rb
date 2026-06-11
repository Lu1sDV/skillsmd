# Fixture covering content_tag with a pre-marked safe body.

def badge(html)
  # ruleid: ruby-xss-content-tag
  content_tag(:span, raw(html))
end

def label(name)
  # ruleid: ruby-xss-content-tag
  content_tag(:div, "<i>#{name}</i>".html_safe)
end

def escaped_badge(name)
  # ok: ruby-xss-content-tag
  content_tag(:span, name)
end
