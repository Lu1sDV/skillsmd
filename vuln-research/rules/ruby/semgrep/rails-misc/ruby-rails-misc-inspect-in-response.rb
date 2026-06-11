# Fixture for object internals leaked via inspect.

class DebugController < ApplicationController
  def show
    user = current_user
    # ruleid: ruby-rails-misc-inspect-in-response
    render plain: user.inspect
  end

  def env_dump
    # ruleid: ruby-rails-misc-inspect-in-response
    render plain: request.env.inspect, status: 200
  end

  def show_safe
    # ok: ruby-rails-misc-inspect-in-response
    render json: { id: current_user.id, name: current_user.name }
  end
end
