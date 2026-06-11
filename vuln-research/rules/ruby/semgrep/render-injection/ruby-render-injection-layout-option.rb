# Fixture for the render layout: option chosen from request input.

class ThemedController < ApplicationController
  def show
    # ruleid: ruby-render-injection-layout-option
    render "themed/show", layout: params[:layout]
  end

  def show_only
    # ruleid: ruby-render-injection-layout-option
    render layout: params[:layout]
  end

  def safe_show
    # ok: ruby-render-injection-layout-option
    render "themed/show", layout: "application"
  end
end
