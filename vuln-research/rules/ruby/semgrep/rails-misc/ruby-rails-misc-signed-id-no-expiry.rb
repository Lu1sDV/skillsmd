# Fixture for unbounded signed id generation.

class ShareLinksController < ApplicationController
  def create
    document = Document.find(params[:id])
    # ruleid: ruby-rails-misc-signed-id-no-expiry
    token = document.signed_id
    render json: { token: token }
  end

  def create_safe
    document = Document.find(params[:id])
    # ok: ruby-rails-misc-signed-id-no-expiry
    token = document.signed_id(expires_in: 15.minutes, purpose: :share)
    render json: { token: token }
  end
end
