# Fixture for the current_user-from-params IDOR detector.

def current_user
  # ruleid: ruby-auth-session-find-current-user-from-params
  @current_user ||= User.find(params[:user_id])
end

def lookup_other
  # ok: ruby-auth-session-find-current-user-from-params
  User.find(params[:user_id])
end

def current_user_session
  # ok: ruby-auth-session-find-current-user-from-params
  @current_user ||= User.find(session[:user_id])
end
