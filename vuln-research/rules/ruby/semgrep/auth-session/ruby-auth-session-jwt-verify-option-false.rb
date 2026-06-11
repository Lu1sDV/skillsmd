# Fixture for the JWT verify:false option detector.

def decode_unverified(token, key)
  # ruleid: ruby-auth-session-jwt-verify-option-false
  JWT.decode(token, key, true, verify: false, algorithm: "HS256")
end

def decode_verified(token, key)
  # ok: ruby-auth-session-jwt-verify-option-false
  JWT.decode(token, key, true, verify: true, algorithm: "HS256")
end
