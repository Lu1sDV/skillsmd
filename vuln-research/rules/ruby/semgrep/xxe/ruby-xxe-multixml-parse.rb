# Fixture for the MultiXml.parse rule.

require "multi_xml"

def decode
  # ruleid: ruby-xxe-multixml-parse
  MultiXml.parse(request.raw_post)
end

def decode_static
  # ok: ruby-xxe-multixml-parse
  MultiXml.parse("<r/>")
end
