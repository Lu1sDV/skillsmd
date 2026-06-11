# Fixture for the insecure cookie transport detector.

def remember(token)
  # ruleid: ruby-auth-session-cookie-secure-false
  cookies[:remember_token] = { value: token, secure: false, httponly: true }
end

def remember_signed(token)
  # ruleid: ruby-auth-session-cookie-secure-false
  cookies.signed[:remember_token] = { value: token, secure: false }
end

def remember_secure(token)
  # ok: ruby-auth-session-cookie-secure-false
  cookies[:remember_token] = { value: token, secure: true, httponly: true }
end
