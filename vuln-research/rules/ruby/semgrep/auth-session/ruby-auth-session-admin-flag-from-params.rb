# Fixture for the tainted privilege-in-session detector.

def grant
  # ruleid: ruby-auth-session-admin-flag-from-params
  session[:admin] = params[:admin]
end

def grant_role
  # ruleid: ruby-auth-session-admin-flag-from-params
  session[:role] = params[:role]
end

def trusted(user)
  # ok: ruby-auth-session-admin-flag-from-params
  session[:admin] = user.admin?
end
