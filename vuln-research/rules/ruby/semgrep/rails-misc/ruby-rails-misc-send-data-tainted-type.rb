# Fixture for tainted send_data content type.

class BlobController < ApplicationController
  def show
    # ruleid: ruby-rails-misc-send-data-tainted-type
    send_data blob.bytes, type: params[:mime]
  end

  def show_chained
    # ruleid: ruby-rails-misc-send-data-tainted-type
    send_data blob.bytes, type: params[:mime].to_s
  end

  def show_safe
    # ok: ruby-rails-misc-send-data-tainted-type
    send_data blob.bytes, type: "application/octet-stream", disposition: "attachment"
  end
end
