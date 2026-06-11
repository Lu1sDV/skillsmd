# Fixture for the DRbObject.new_with_uri rule.
# Flagged line connects to a runtime URI; safe line connects to a fixed literal URI.

require "drb"

def remote(uri)
  # ruleid: ruby-deserialization-drbobject-new-with-uri
  DRbObject.new_with_uri(uri)
end

def remote_fixed
  # ok: ruby-deserialization-drbobject-new-with-uri
  DRbObject.new_with_uri("druby://127.0.0.1:8787")
end
