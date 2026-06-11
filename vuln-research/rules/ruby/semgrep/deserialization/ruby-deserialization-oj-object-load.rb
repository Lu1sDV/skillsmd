# Fixture for the Oj.object_load rule.
# Flagged line force-loads objects from external JSON; safe line uses a literal.

require "oj"

def hydrate(body)
  # ruleid: ruby-deserialization-oj-object-load
  Oj.object_load(body)
end

def hydrate_const
  # ok: ruby-deserialization-oj-object-load
  Oj.object_load("{}")
end
