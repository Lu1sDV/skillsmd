class SessionsController < ActionController::Base
  # True positive: the redirect target comes straight from a request parameter,
  # so an attacker can point the victim at any external host.
  def show
    redirect_to params[:return_to]
  end

  # Safe: the redirect target is a fixed, hard-coded relative path.
  def safe_show
    redirect_to "/dashboard"
  end
end
