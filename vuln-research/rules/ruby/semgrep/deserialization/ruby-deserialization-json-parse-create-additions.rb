# Fixture for the JSON.parse create_additions rule.
# Flagged line opts into object additions; safe line parses as plain data.

require "json"

def decode_obj(body)
  # ruleid: ruby-deserialization-json-parse-create-additions
  JSON.parse(body, create_additions: true)
end

def decode_data(body)
  # ok: ruby-deserialization-json-parse-create-additions
  JSON.parse(body, symbolize_names: true)
end
