# Fixture for user-controlled ActionCable subscription target.

class ChatChannel < ApplicationCable::Channel
  def subscribed
    # ruleid: ruby-rails-misc-stream-from-tainted-channel
    stream_from params[:channel]
  end

  def subscribed_interp
    # ruleid: ruby-rails-misc-stream-from-tainted-channel
    stream_from "chat_#{params[:room_id]}"
  end

  def subscribed_safe
    # ok: ruby-rails-misc-stream-from-tainted-channel
    stream_from "chat_#{current_user.id}"
  end
end
