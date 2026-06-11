# Fixture for lookup_context.find_template driven by request input.

class TemplateController < ApplicationController
  def preview
    # ruleid: ruby-render-injection-find-template-params
    tmpl = lookup_context.find_template(params[:name], [], false)
    render body: tmpl.source
  end

  def safe_preview
    # ok: ruby-render-injection-find-template-params
    tmpl = lookup_context.find_template("previews/default", [], false)
    render body: tmpl.source
  end
end
