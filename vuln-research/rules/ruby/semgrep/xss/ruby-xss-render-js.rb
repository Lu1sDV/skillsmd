# Fixture covering render js: executable response body.

def alert(msg)
  # ruleid: ruby-xss-render-js
  render js: "alert('#{msg}')"
end

def alert_param
  # ruleid: ruby-xss-render-js
  render js: params[:script]
end

def fixed_js
  # ok: ruby-xss-render-js
  render js: "window.location.reload()"
end
