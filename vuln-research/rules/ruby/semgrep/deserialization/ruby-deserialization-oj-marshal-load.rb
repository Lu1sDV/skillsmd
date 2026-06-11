# Fixture for the Oj.marshal_load rule.
# Flagged line deserializes external bytes; safe line uses a literal payload.

require "oj"

def restore(blob)
  # ruleid: ruby-deserialization-oj-marshal-load
  Oj.marshal_load(blob)
end

def restore_const
  # ok: ruby-deserialization-oj-marshal-load
  Oj.marshal_load("{}")
end
