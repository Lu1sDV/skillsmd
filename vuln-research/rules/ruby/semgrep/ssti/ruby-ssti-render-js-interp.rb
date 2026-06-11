# Fixture for render js: built from an interpolated string.

class AlertController
  def ping(params)
    # ruleid: ruby-ssti-render-js-interp
    render(js: "alert('#{params[:msg]}')")
  end

  def ping_safe
    # ok: ruby-ssti-render-js-interp
    render(js: "alert('hello')")
  end
end
