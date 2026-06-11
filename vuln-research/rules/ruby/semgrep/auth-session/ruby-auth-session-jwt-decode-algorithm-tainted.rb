# Fixture for the JWT attacker-controlled algorithm detector.

def decode_dynamic(token, key)
  # ruleid: ruby-auth-session-jwt-decode-algorithm-tainted
  JWT.decode(token, key, true, algorithm: params[:alg])
end

def decode_dynamic_list(token, key)
  # ruleid: ruby-auth-session-jwt-decode-algorithm-tainted
  JWT.decode(token, key, true, algorithms: params[:algs])
end

def decode_fixed(token, key)
  # ok: ruby-auth-session-jwt-decode-algorithm-tainted
  JWT.decode(token, key, true, algorithm: "RS256")
end
