# Fixture for raw HTML flash from request input.

class FeedbackController < ApplicationController
  def create
    # ruleid: ruby-rails-misc-flash-tainted-html
    flash[:notice] = params[:message].html_safe
    redirect_to root_path
  end

  def create_raw
    # ruleid: ruby-rails-misc-flash-tainted-html
    flash[:alert] = raw(params[:message])
    redirect_to root_path
  end

  def create_safe
    # ok: ruby-rails-misc-flash-tainted-html
    flash[:notice] = params[:message].to_s
    redirect_to root_path
  end
end
