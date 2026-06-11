# Fixture for the Devise bypass_sign_in detector.

def impersonate(user)
  # ruleid: ruby-auth-session-devise-bypass-sign-in
  bypass_sign_in(user)
end

def normal(user)
  # ok: ruby-auth-session-devise-bypass-sign-in
  sign_in(user)
end
