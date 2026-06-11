# Fixture for the YAML.unsafe_load rule.
# Flagged line loads external YAML unsafely; safe line uses a literal document.

require "yaml"

def load_profile(raw)
  # ruleid: ruby-deserialization-yaml-unsafe-load
  YAML.unsafe_load(raw)
end

def seed
  # ok: ruby-deserialization-yaml-unsafe-load
  YAML.unsafe_load("---\nname: seed\n")
end
