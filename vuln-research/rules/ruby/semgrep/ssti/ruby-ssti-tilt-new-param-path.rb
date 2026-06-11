# Fixture for Tilt selecting a template path from request input.

class TemplateController
  def render_path(params)
    # ruleid: ruby-ssti-tilt-new-param-path
    Tilt.new(params[:path]).render(self)
  end

  def render_path_safe(params)
    path = TEMPLATE_PATHS.fetch(params[:key], "views/default.erb")
    # ok: ruby-ssti-tilt-new-param-path
    Tilt.new(path).render(self)
  end
end
