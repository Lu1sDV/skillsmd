# Fixture covering content_for storing a raw fragment.

def head_inject(meta)
  # ruleid: ruby-xss-content-for-raw
  content_for(:head, raw(meta))
end

def head_param
  # ruleid: ruby-xss-content-for-raw
  content_for(:head, params[:meta].html_safe)
end

def head_safe(title)
  # ok: ruby-xss-content-for-raw
  content_for(:head, title)
end
