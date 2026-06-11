# Fixture for the Psych.load rule.
# Flagged line loads external YAML via Psych; safe lines allowlist classes or use a literal.

require "psych"

def parse_doc(body)
  # ruleid: ruby-deserialization-psych-load
  Psych.load(body)
end

def parse_doc_safe(body)
  # ok: ruby-deserialization-psych-load
  Psych.load(body, permitted_classes: [Symbol])
end

def parse_const
  # ok: ruby-deserialization-psych-load
  Psych.load("--- ok\n")
end
