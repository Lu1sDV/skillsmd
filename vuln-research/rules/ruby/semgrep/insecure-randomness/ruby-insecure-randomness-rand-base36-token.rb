# Fixture for the base36 rand token idiom.

def short_code
  # ruleid: ruby-insecure-randomness-rand-base36-token
  code = rand(36**8).to_s(36)
  code
end

def short_code_secure
  # ok: ruby-insecure-randomness-rand-base36-token
  code = SecureRandom.alphanumeric(8)
  code
end
