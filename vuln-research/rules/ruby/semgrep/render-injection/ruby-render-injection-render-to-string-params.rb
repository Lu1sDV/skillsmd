# Fixture for render_to_string fed a request-controlled template.

class PdfController < ApplicationController
  def generate
    # ruleid: ruby-render-injection-render-to-string-params
    html = render_to_string(template: params[:tpl])
    PdfKit.new(html).to_pdf
  end

  def safe_generate
    # ok: ruby-render-injection-render-to-string-params
    html = render_to_string(template: "pdf/invoice")
    PdfKit.new(html).to_pdf
  end
end
