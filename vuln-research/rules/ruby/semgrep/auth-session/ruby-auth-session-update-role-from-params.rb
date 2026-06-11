# Fixture for the privilege-update-from-params detector.

def promote(user)
  # ruleid: ruby-auth-session-update-role-from-params
  user.update(role: params[:role])
end

def set_admin(user)
  # ruleid: ruby-auth-session-update-role-from-params
  user.admin = params[:admin]
end

def rename(user)
  # ok: ruby-auth-session-update-role-from-params
  user.update(name: params[:name])
end
