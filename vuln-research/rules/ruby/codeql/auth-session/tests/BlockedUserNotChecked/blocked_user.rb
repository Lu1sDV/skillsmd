# Test fixtures for rb/auth-session-blocked-user-not-checked (CWE-287).

# BAD: looks up user via with_reset_password_token and proceeds to reset password
# without any blocked? guard — mirrors GitLab ac8c5c37d035 (passwords_controller.rb).
class PasswordsController
  def update
    user = User.with_reset_password_token(params[:reset_password_token])
    user.reset_password(params[:password], params[:password_confirmation])
  end
end

# BAD: looks up user via find_by_login and signs in without checking blocked? —
# mirrors the find_by_login pattern in GitLab auth flows.
class SessionsController
  def create
    user = User.find_by_login(params[:login])
    sign_in(user)
  end
end

# GOOD: same with_reset_password_token finder but includes a blocked? guard —
# mirrors the fix in ac8c5c37d035.
class SafePasswordsController
  def update
    user = User.with_reset_password_token(params[:reset_password_token])
    return redirect_to new_session_path if user&.blocked?
    user.reset_password(params[:password], params[:password_confirmation])
  end
end

# GOOD: find_by_login with blocked? check present — should NOT be flagged.
class SafeSessionsController
  def create
    user = User.find_by_login(params[:login])
    return render :blocked if user.blocked?
    sign_in(user)
  end
end
