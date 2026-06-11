# Fixture for the render partial: option chosen from request input.

class WidgetController < ApplicationController
  def fragment
    # ruleid: ruby-render-injection-partial-option
    render partial: params[:widget]
  end

  def fragment_locals
    # ruleid: ruby-render-injection-partial-option
    render partial: params[:widget], locals: { x: 1 }
  end

  def safe_fragment
    # ok: ruby-render-injection-partial-option
    render partial: "widgets/sidebar"
  end
end
