# Fixture for unscoped signed blob materialization.

class BlobsController < ApplicationController
  def show
    # ruleid: ruby-rails-misc-find-signed-tainted
    blob = ActiveStorage::Blob.find_signed(params[:signed_id])
    redirect_to blob.url
  end

  def show_bang
    # ruleid: ruby-rails-misc-find-signed-tainted
    ActiveStorage::Blob.find_signed!(params[:signed_id])
  end

  def show_safe
    # ok: ruby-rails-misc-find-signed-tainted
    ActiveStorage::Blob.find_signed(params[:signed_id], purpose: :avatar)
  end
end
