# Fixture for the Plist marshal rule.
# Flagged line enables Marshal-backed plist parsing; safe line disables it.

require "plist"

def parse_plist(body)
  # ruleid: ruby-deserialization-plist-marshal
  Plist.parse_xml(body, marshal: true)
end

def parse_plist_safe(body)
  # ok: ruby-deserialization-plist-marshal
  Plist.parse_xml(body, marshal: false)
end
