# Fixture for the tainted session identity detector.

def impersonate
  # ruleid: ruby-auth-session-id-from-params
  session[:user_id] = params[:user_id]
end

def from_authenticated(user)
  # ok: ruby-auth-session-id-from-params
  session[:user_id] = user.id
end
