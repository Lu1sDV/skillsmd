# Fixture for tainted Turbo Stream target id.

class MessagesController < ApplicationController
  def update
    # ruleid: ruby-rails-misc-turbo-stream-tainted-target
    render turbo_stream: turbo_stream.replace(params[:target], partial: "messages/row")
  end

  def append_row
    # ruleid: ruby-rails-misc-turbo-stream-tainted-target
    render turbo_stream: turbo_stream.append(params[:dom_id], partial: "messages/row")
  end

  def update_safe
    # ok: ruby-rails-misc-turbo-stream-tainted-target
    render turbo_stream: turbo_stream.replace(dom_id(@message), partial: "messages/row")
  end
end
