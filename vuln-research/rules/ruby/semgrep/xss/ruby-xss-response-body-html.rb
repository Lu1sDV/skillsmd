# Fixture covering tainted assignment to the response body.

def render_raw
  # ruleid: ruby-xss-response-body-html
  response.body = "<h1>#{params[:title]}</h1>"
end

def render_param
  # ruleid: ruby-xss-response-body-html
  response.body = params[:html]
end

def render_static
  # ok: ruby-xss-response-body-html
  response.body = "<h1>OK</h1>"
end
