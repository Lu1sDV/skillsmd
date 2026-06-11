# Fixture covering strip_tags result trusted as safe HTML.

def excerpt
  # ruleid: ruby-xss-strip-tags-trust
  strip_tags(params[:body]).html_safe
end

def excerpt_raw(body)
  # ruleid: ruby-xss-strip-tags-trust
  raw(strip_tags(body))
end

def excerpt_safe
  # ok: ruby-xss-strip-tags-trust
  strip_tags(params[:body])
end
