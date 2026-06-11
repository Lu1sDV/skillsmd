class User < ActiveRecord::Base
end

class CommentsController < ApplicationController
  # True positive: a field read back from a persisted ActiveRecord row is marked
  # html_safe, bypassing escaping, so a payload stored earlier in `handle`
  # executes in every viewer's browser. `User.find(1).handle` is a stored source;
  # html_safe is the rendering sink.
  def show
    user = User.find(1)
    @bio = user.handle.html_safe
    render "comments/show"
  end

  # Safe: a static literal banner, nothing read from storage.
  def banner
    @bio = "Welcome".html_safe
    render "comments/banner"
  end
end
