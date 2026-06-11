# Fixture for exception detail rendered to the client.

class OrdersController < ApplicationController
  def create
    place_order
  rescue => e
    # ruleid: ruby-rails-misc-render-exception-message
    render plain: e.message, status: 500
  end

  def update
    update_order
  rescue StandardError => e
    # ruleid: ruby-rails-misc-render-exception-message
    render json: { error: e.message }, status: 422
  end

  def destroy
    remove_order
  rescue => e
    Rails.logger.error(e.full_message)
    # ok: ruby-rails-misc-render-exception-message
    render json: { error: "Unable to process request" }, status: 500
  end
end
