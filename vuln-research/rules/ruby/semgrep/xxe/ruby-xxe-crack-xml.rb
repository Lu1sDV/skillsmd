# Fixture for the Crack::XML.parse rule.

require "crack"

def parse_remote
  # ruleid: ruby-xxe-crack-xml
  Crack::XML.parse(request.body.read)
end

def parse_static
  # ok: ruby-xxe-crack-xml
  Crack::XML.parse("<a/>")
end
