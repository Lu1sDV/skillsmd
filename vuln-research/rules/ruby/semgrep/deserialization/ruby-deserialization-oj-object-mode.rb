# Fixture for the Oj object-mode rule.
# Flagged line loads JSON in object mode; safe line uses strict mode.

require "oj"

def parse_obj(body)
  # ruleid: ruby-deserialization-oj-object-mode
  Oj.load(body, mode: :object)
end

def parse_strict(body)
  # ok: ruby-deserialization-oj-object-mode
  Oj.load(body, mode: :strict)
end
