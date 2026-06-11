# Fixture for object_id-derived identifiers.

def session_for(user)
  # ruleid: ruby-insecure-randomness-object-id-token
  session_token = user.object_id.to_s(16)
  session_token
end

def session_for_secure(user)
  # ok: ruby-insecure-randomness-object-id-token
  session_token = SecureRandom.hex(16)
  session_token
end
