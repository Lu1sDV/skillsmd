# Fixture for render layout: selected from a request parameter.

class DashboardController
  def show(params)
    # ruleid: ruby-ssti-render-layout-param
    render("dashboard", layout: params[:layout])
  end

  def show_safe(params)
    layout = LAYOUTS.fetch(params[:layout], "application")
    # ok: ruby-ssti-render-layout-param
    render("dashboard", layout: layout)
  end
end
