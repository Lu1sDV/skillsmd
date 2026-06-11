# Fixture for explicit PRNG re-seeding.

def reseed_fixed
  # ruleid: ruby-insecure-randomness-srand-seed
  srand(1234)
  rand(100)
end

def reseed_time
  # ruleid: ruby-insecure-randomness-srand-seed
  Random.srand(Time.now.to_i)
  rand(100)
end

def reseed_entropy
  # ok: ruby-insecure-randomness-srand-seed
  srand
  rand(100)
end
