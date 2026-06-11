# Fixture for the Oj default-mode load rule.
# Flagged line loads external JSON with no explicit mode; safe lines pin a mode or use a literal.

require "oj"

def parse_ambient(body)
  # ruleid: ruby-deserialization-oj-default-load
  Oj.load(body)
end

def parse_pinned(body)
  # ok: ruby-deserialization-oj-default-load
  Oj.load(body, mode: :strict)
end

def parse_const
  # ok: ruby-deserialization-oj-default-load
  Oj.load("{}")
end
