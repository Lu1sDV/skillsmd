# Fixture for the JWT signature-verification-disabled detector.

def parse_unverified(token)
  # ruleid: ruby-auth-session-jwt-decode-verify-disabled
  JWT.decode(token, nil, false)
end

def parse_unverified_opts(token, secret)
  # ruleid: ruby-auth-session-jwt-decode-verify-disabled
  JWT.decode(token, secret, false, algorithm: "HS256")
end

def parse_verified(token, secret)
  # ok: ruby-auth-session-jwt-decode-verify-disabled
  JWT.decode(token, secret, true, algorithm: "HS256")
end
