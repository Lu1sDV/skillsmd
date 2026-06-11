# Fixture for the wildcard-origin-with-credentials CORS detector.

def insecure
  # ruleid: ruby-auth-session-cors-credentials-any-origin
  origins "*"
  resource "/api/*", headers: :any, credentials: true
end

def scoped
  # ok: ruby-auth-session-cors-credentials-any-origin
  origins "https://app.example.com"
  resource "/api/*", headers: :any, credentials: true
end
