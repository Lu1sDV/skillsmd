# Fixture for Slim template path taken from request input.

class SlimController
  def render_view(params)
    # ruleid: ruby-ssti-slim-file-read-param
    Slim::Template.new(params[:tpl]).render(scope)
  end

  def render_view_safe(params)
    tpl = SLIM_VIEWS.fetch(params[:key], "views/home.slim")
    # ok: ruby-ssti-slim-file-read-param
    Slim::Template.new(tpl).render(scope)
  end
end
