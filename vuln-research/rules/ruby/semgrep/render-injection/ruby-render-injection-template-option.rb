# Fixture for the render template: option fed from request input.

class ReportController < ApplicationController
  def view
    # ruleid: ruby-render-injection-template-option
    render template: params[:tpl]
  end

  def view_with_layout
    # ruleid: ruby-render-injection-template-option
    render template: params[:tpl], layout: "report"
  end

  def safe_view
    # ok: ruby-render-injection-template-option
    render template: "reports/view"
  end
end
