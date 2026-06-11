# Fixture for the unsafe Devise sign_in detector.

def login_by_id
  # ruleid: ruby-auth-session-devise-sign-in-from-params
  sign_in(User.find(params[:id]))
end

def login_direct
  # ruleid: ruby-auth-session-devise-sign-in-from-params
  sign_in(params[:user])
end

def login_verified(user)
  # ok: ruby-auth-session-devise-sign-in-from-params
  sign_in(user) if user.valid_password?(password)
end
