# Fixture for render formats: chosen from request input.

class ExportController < ApplicationController
  def data
    # ruleid: ruby-render-injection-format-param
    render template: "export/data", formats: [params[:fmt]]
  end

  def safe_data
    # ok: ruby-render-injection-format-param
    render template: "export/data", formats: [:json]
  end
end
