# Fixture for the Plist.parse_xml rule.

require "plist"

def load_prefs
  # ruleid: ruby-xxe-plist-parse
  Plist.parse_xml(request.body.read)
end

def load_static
  # ok: ruby-xxe-plist-parse
  Plist.parse_xml("<plist></plist>")
end
