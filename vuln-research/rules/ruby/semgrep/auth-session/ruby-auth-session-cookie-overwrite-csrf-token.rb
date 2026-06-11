# Fixture for the client-set CSRF-token cookie detector.

def seed
  # ruleid: ruby-auth-session-cookie-overwrite-csrf-token
  cookies[:csrf_token] = params[:token]
end

def seed_safe
  # ok: ruby-auth-session-cookie-overwrite-csrf-token
  cookies[:csrf_token] = form_authenticity_token
end
