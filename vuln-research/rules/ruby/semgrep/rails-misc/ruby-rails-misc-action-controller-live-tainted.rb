# Fixture for tainted ActionController::Live write.

class FeedController < ApplicationController
  include ActionController::Live

  def stream
    # ruleid: ruby-rails-misc-action-controller-live-tainted
    response.stream.write(params[:message])
  ensure
    response.stream.close
  end

  def stream_interp
    # ruleid: ruby-rails-misc-action-controller-live-tainted
    response.stream.write("data: #{params[:payload]}\n\n")
  end

  def stream_safe
    safe = ERB::Util.html_escape(params[:message].to_s)
    # ok: ruby-rails-misc-action-controller-live-tainted
    response.stream.write(safe)
  end
end
