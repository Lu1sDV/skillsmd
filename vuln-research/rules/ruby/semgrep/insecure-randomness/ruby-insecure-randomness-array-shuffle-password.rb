# Fixture for shuffle-based secret assembly.

POOL = (("a".."z").to_a + ("A".."Z").to_a)

def temp_password
  # ruleid: ruby-insecure-randomness-array-shuffle-password
  pw = POOL.shuffle.first(10).join
  pw
end

def temp_password_secure
  # ok: ruby-insecure-randomness-array-shuffle-password
  pw = POOL.shuffle(random: SecureRandom).first(10).join
  pw
end
