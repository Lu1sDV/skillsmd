# Fixture for the Random class feeding a sensitive value.

def make_session
  # ruleid: ruby-insecure-randomness-random-rand-token
  session_id = Random.rand(2**64)
  session_id.to_s(16)
end

def make_session_secure
  # ok: ruby-insecure-randomness-random-rand-token
  session_id = SecureRandom.hex(16)
  session_id
end

def pick_color
  # ok: ruby-insecure-randomness-random-rand-token
  shade = Random.rand(255)
  shade
end
