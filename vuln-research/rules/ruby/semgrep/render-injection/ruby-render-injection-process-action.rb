# Fixture for controller process dispatch from request input.

class ProxyController < ApplicationController
  def forward
    inner = InnerController.new
    # ruleid: ruby-render-injection-process-action
    inner.process(params[:action])
  end

  def safe_forward
    inner = InnerController.new
    # ok: ruby-render-injection-process-action
    inner.process(:index)
  end
end
