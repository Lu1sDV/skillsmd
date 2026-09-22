# Test fixtures for rb/auth-session-2fa-session-bypass (CWE-308).

# BAD: User.find with session[:otp_user_id] as the direct argument -- mirrors the
# vulnerable shape in GitLab sessions_controller.rb before fix ac6a2224c865.
class VulnerableSessionsController
  def find_user
    if session[:otp_user_id]
      User.find(session[:otp_user_id])   # BAD: unconditional session trust, no identity guard
    elsif user_params[:login]
      User.find_by_login(user_params[:login])
    end
  end
end

# BAD: find_by_id variant of the same smell.
class VulnerableSessionsController2
  def authenticate_with_two_factor
    user = User.find_by_id(session[:otp_user_id])  # BAD: find_by_id on raw session value
    authenticate_otp(user)
  end
end

# GOOD: lookup is by submitted login credential, not the raw session value; the
# session[:otp_user_id] value appears only in a guard comparison, not as the
# direct argument to User.find/find_by_id -- mirrors the fixed shape in ac6a2224c865.
class SafeSessionsController
  def find_user
    if user_params[:login]
      User.find_by_login(user_params[:login])   # GOOD: credential-based lookup
    end
  end

  def authenticate_with_two_factor
    user = find_user
    clear_two_factor_attempt! if session[:otp_user_id] != user.id  # GOOD: guard only
    authenticate_otp(user)
  end
end

# GOOD: User.find_by_id called with a non-session argument should NOT be flagged.
class SafeController
  def show
    user = User.find_by_id(params[:id])   # GOOD: params, not session[:otp_user_id]
    render json: user
  end
end
