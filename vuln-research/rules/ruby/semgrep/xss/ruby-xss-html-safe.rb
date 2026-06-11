# Fixture covering the html_safe escaping bypass.

def render_bio(user)
  # ruleid: ruby-xss-html-safe
  "<p>#{user.bio}</p>".html_safe
end

def echo
  # ruleid: ruby-xss-html-safe
  params[:msg].html_safe
end

def static_label
  # ok: ruby-xss-html-safe
  "<span>online</span>".html_safe
end
