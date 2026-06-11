# Fixture for render_to_body fed a request-controlled template.

class ComposeController < ApplicationController
  def build
    # ruleid: ruby-render-injection-render-to-body
    body = render_to_body(template: params[:section])
    store(body)
  end

  def safe_build
    # ok: ruby-render-injection-render-to-body
    body = render_to_body(template: "compose/section")
    store(body)
  end
end
