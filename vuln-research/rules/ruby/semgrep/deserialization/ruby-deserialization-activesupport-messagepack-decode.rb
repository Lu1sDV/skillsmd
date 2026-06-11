# Fixture for the ActiveSupport::MessagePack.decode rule.
# Flagged line decodes external bytes; safe line decodes a literal.

def decode_mp(body)
  # ruleid: ruby-deserialization-activesupport-messagepack-decode
  ActiveSupport::MessagePack.decode(body)
end

def decode_mp_const
  # ok: ruby-deserialization-activesupport-messagepack-decode
  ActiveSupport::MessagePack.decode("\x80")
end
