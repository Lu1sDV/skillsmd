# Fixture for render with a request-derived options hash splatted in.

class FlexibleController < ApplicationController
  def show
    # ruleid: ruby-render-injection-options-splat
    render(**params.to_unsafe_h)
  end

  def safe_show
    # ok: ruby-render-injection-options-splat
    render(template: "flexible/show", status: :ok)
  end
end
