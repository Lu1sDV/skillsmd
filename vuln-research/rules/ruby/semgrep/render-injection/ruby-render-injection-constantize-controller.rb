# Fixture for resolving a controller class by constantizing request input.

class GatewayController < ApplicationController
  def dispatch_to
    # ruleid: ruby-render-injection-constantize-controller
    klass = "#{params[:controller]}Controller".constantize
    klass.new.handle
  end

  def safe_dispatch
    # ok: ruby-render-injection-constantize-controller
    klass = ALLOWED_CONTROLLERS.fetch(params[:controller])
    klass.new.handle
  end
end
