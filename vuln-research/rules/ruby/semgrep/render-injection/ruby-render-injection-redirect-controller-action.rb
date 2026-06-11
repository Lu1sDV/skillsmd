# Fixture for redirect_to resolving controller/action from request input.

class DispatchController < ApplicationController
  def route
    # ruleid: ruby-render-injection-redirect-controller-action
    redirect_to controller: params[:c], action: params[:a]
  end

  def route_action_only
    # ruleid: ruby-render-injection-redirect-controller-action
    redirect_to(action: params[:a], status: 302)
  end

  def safe_route
    # ok: ruby-render-injection-redirect-controller-action
    redirect_to controller: "home", action: "index"
  end
end
