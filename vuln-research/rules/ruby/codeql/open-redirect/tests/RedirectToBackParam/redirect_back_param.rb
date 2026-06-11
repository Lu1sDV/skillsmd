class LoginController < ActionController::Base
  # True positive: an unvalidated "return to" parameter is used as the redirect
  # target, allowing an attacker-crafted link to bounce the victim off-site.
  def after_login
    redirect_to params[:return_url]
  end

  # Safe: the parameter is compared against a constant allow-list value before
  # being used, so the comparison guard sanitizes the redirect target.
  def guarded_login
    target = params[:return_url]
    if target == "/dashboard"
      redirect_to target
    else
      redirect_to "/home"
    end
  end
end
