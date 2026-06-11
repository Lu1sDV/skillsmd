# Fixture for the Psych.unsafe_load rule.
# Flagged line loads external YAML unsafely; safe line uses a literal.

require "psych"

def ingest(body)
  # ruleid: ruby-deserialization-psych-unsafe-load
  Psych.unsafe_load(body)
end

def ingest_const
  # ok: ruby-deserialization-psych-unsafe-load
  Psych.unsafe_load("--- 1\n")
end
