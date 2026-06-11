# Fixture for positional render of a request-controlled template name.

class WidgetController
  def show(params)
    # ruleid: ruby-ssti-render-positional-param
    render(params[:partial])
  end

  def show_safe
    # ok: ruby-ssti-render-positional-param
    render("widgets/show")
  end
end
