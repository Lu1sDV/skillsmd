# Fixture for rendering a bare request parameter as a template name.

class PageController < ApplicationController
  def show
    # ruleid: ruby-render-injection-render-bare-params
    render params[:template]
  end

  def safe_show
    # ok: ruby-render-injection-render-bare-params
    render "pages/show"
  end
end
