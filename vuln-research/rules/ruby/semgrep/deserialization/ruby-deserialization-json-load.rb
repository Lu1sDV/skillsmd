# Fixture for the JSON.load rule.
# Flagged line loads external JSON with additions enabled; safe line uses JSON.parse.

require "json"

def decode(body)
  # ruleid: ruby-deserialization-json-load
  JSON.load(body)
end

def decode_safe(body)
  # ok: ruby-deserialization-json-load
  JSON.parse(body)
end
