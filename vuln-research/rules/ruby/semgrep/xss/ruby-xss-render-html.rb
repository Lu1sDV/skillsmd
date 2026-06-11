# Fixture covering render html: response body.

def message(text)
  # ruleid: ruby-xss-render-html
  render html: "<div>#{text}</div>"
end

def message_param
  # ruleid: ruby-xss-render-html
  render html: params[:body]
end

def static_page
  # ok: ruby-xss-render-html
  render html: "<div>welcome</div>"
end
