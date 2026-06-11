# Fixture for the JWT alg:none detector.

def mint(payload)
  # ruleid: ruby-auth-session-jwt-none-algorithm
  JWT.encode(payload, nil, "none")
end

def verify_none(token)
  # ruleid: ruby-auth-session-jwt-none-algorithm
  JWT.decode(token, nil, true, algorithm: "none")
end

def mint_signed(payload, secret)
  # ok: ruby-auth-session-jwt-none-algorithm
  JWT.encode(payload, secret, "HS256")
end
