# Fixture for cross-tenant ActionCable broadcast target.

class NotifyService
  def push(params, payload)
    # ruleid: ruby-rails-misc-actioncable-broadcast-tainted-stream
    ActionCable.server.broadcast(params[:stream], payload)
  end

  def push_interp(params, payload)
    # ruleid: ruby-rails-misc-actioncable-broadcast-tainted-stream
    ActionCable.server.broadcast("room_#{params[:room]}", payload)
  end

  def push_safe(current_user, payload)
    # ok: ruby-rails-misc-actioncable-broadcast-tainted-stream
    ActionCable.server.broadcast("user_#{current_user.id}", payload)
  end
end
