# Test fixtures for rb/auth-session-missing-rate-limit (CWE-307).

# BAD: login action calls authenticate_user! but no check_rate_limit! —
# mirrors the pattern fixed in 4b98496b4ab3 / 2bc1a70de269.
class SessionsController
  def create
    authenticate_user!
    sign_in(resource)
  end
end

# BAD: password reset action uses with_reset_password_token without rate limit.
class PasswordsController
  def reset_password
    user = User.with_reset_password_token(params[:token])
    user.reset_password(params[:password], params[:password_confirmation])
  end
end

# GOOD: same login action but has check_rate_limit! guard at the top.
class RateLimitedSessionsController
  def create
    check_rate_limit!(:user_sign_in, scope: [request.ip])
    authenticate_user!
    sign_in(resource)
  end
end

# GOOD: import action protected via before_action lambda with check_rate_limit!.
class Import::GiteaController
  before_action -> { check_rate_limit!(:gitea_import, scope: current_user, redirect_back: true) }, only: :status

  def status
    authenticate_user!
    render :status
  end
end
