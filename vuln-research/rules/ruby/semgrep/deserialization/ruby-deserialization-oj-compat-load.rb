# Fixture for the Oj compat-mode rule.
# Flagged line uses compat mode on external JSON; safe line uses strict mode.

require "oj"

def parse_compat(body)
  # ruleid: ruby-deserialization-oj-compat-load
  Oj.load(body, mode: :compat)
end

def parse_strict(body)
  # ok: ruby-deserialization-oj-compat-load
  Oj.load(body, mode: :strict)
end
