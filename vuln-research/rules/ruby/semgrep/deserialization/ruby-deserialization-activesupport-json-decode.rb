# Fixture for the ActiveSupport::JSON.decode rule.
# Flagged line decodes external JSON; safe line decodes a literal.

def decode_payload(body)
  # ruleid: ruby-deserialization-activesupport-json-decode
  ActiveSupport::JSON.decode(body)
end

def decode_const
  # ok: ruby-deserialization-activesupport-json-decode
  ActiveSupport::JSON.decode("{}")
end
