# Fixture for the render action: option resolved from request input.

class StepController < ApplicationController
  def advance
    # ruleid: ruby-render-injection-action-option
    render action: params[:step]
  end

  def safe_advance
    # ok: ruby-render-injection-action-option
    render action: :summary
  end
end
