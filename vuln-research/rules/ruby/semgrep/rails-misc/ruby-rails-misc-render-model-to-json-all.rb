# Fixture for full-attribute model serialization.

class UsersController < ApplicationController
  def show
    user = User.find(params[:id])
    # ruleid: ruby-rails-misc-render-model-to-json-all
    render json: user.attributes
  end

  def show_safe
    user = User.find(params[:id])
    # ok: ruby-rails-misc-render-model-to-json-all
    render json: user.as_json(only: [:id, :name, :avatar_url])
  end
end
