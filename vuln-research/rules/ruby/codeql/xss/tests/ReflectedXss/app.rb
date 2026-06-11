class UsersController < ApplicationController
  # True positive: a request parameter is marked html_safe, bypassing the
  # automatic HTML escaping, so the reflected value can carry a script payload.
  def show
    name = params[:name]
    @greeting = name.html_safe
    render "users/show"
  end

  # Safe: a constant literal is marked html_safe; no request-derived data.
  def about
    @greeting = "About us".html_safe
    render "users/about"
  end
end
