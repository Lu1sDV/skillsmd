# Fixture covering sanitize with a client-controlled policy.

def clean(html)
  # ruleid: ruby-xss-sanitize-user-tags
  sanitize(html, tags: params[:tags])
end

def clean_attrs(html)
  # ruleid: ruby-xss-sanitize-user-tags
  sanitize(html, attributes: params[:attrs])
end

def clean_fixed(html)
  # ok: ruby-xss-sanitize-user-tags
  sanitize(html, tags: %w[p br strong])
end
