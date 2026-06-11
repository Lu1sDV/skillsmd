# Fixture for seeded Random construction.

def deterministic_gen
  # ruleid: ruby-insecure-randomness-random-new-fixed-seed
  prng = Random.new(42)
  prng.rand(1000)
end

def entropy_gen
  # ok: ruby-insecure-randomness-random-new-fixed-seed
  prng = Random.new
  prng.rand(1000)
end
