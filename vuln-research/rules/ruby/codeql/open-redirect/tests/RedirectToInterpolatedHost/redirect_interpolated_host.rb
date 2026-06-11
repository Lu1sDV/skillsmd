class PagesController < ActionController::Base
  # True positive: the tainted value controls the host (it is the prefix of the
  # interpolated URL), so the redirect can target an arbitrary external origin.
  def go
    redirect_to "#{params[:host]}/welcome"
  end

  # Safe: the tainted value is only the suffix; the URL is rooted at a constant
  # relative prefix, so the host cannot be controlled by the attacker.
  def go_safe
    redirect_to "/welcome/#{params[:slug]}"
  end
end
