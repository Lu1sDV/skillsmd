# Fixture for Array#sample token generation.

CHARSET = ("a".."z").to_a + ("0".."9").to_a

def gen_password
  # ruleid: ruby-insecure-randomness-array-sample-token
  pw = CHARSET.sample(12).join
  pw
end

def gen_password_secure
  # ok: ruby-insecure-randomness-array-sample-token
  pw = CHARSET.sample(12, random: SecureRandom).join
  pw
end
