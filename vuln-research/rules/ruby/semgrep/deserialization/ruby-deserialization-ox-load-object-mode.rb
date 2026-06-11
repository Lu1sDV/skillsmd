# Fixture for the Ox.load object-mode rule.
# Flagged line loads XML in object mode; safe line uses hash mode.

require "ox"

def load_obj(body)
  # ruleid: ruby-deserialization-ox-load-object-mode
  Ox.load(body, mode: :object)
end

def load_hash(body)
  # ok: ruby-deserialization-ox-load-object-mode
  Ox.load(body, mode: :hash)
end
