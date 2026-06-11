# Fixture for the over-broad Psych.safe_load allowlist rule.
# Flagged line permits a dangerous class; safe line permits only inert value types.

require "psych"

def load_broad(body)
  # ruleid: ruby-deserialization-psych-safe-load-broad
  Psych.safe_load(body, permitted_classes: [Symbol, Class])
end

def load_narrow(body)
  # ok: ruby-deserialization-psych-safe-load-broad
  Psych.safe_load(body, permitted_classes: [Symbol, Date, Time])
end
