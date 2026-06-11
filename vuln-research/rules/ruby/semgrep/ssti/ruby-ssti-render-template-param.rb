# Fixture for render template: chosen from a request parameter.

class ViewController
  def show(params)
    # ruleid: ruby-ssti-render-template-param
    render(template: params[:view])
  end

  def show_safe(params)
    name = ALLOWED_VIEWS.fetch(params[:view], "home")
    # ok: ruby-ssti-render-template-param
    render(template: name)
  end
end
