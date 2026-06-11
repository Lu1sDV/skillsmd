# Fixture for the plain remember-token cookie detector.

def persist(token)
  # ruleid: ruby-auth-session-remember-token-plain-cookie
  cookies[:remember_token] = token
end

def persist_signed(token)
  # ok: ruby-auth-session-remember-token-plain-cookie
  cookies.signed[:remember_token] = token
end
