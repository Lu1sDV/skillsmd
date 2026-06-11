# Fixture for the Ox.parse_obj rule.
# Flagged line rebuilds objects from external XML; safe line uses a literal document.

require "ox"

def from_xml(body)
  # ruleid: ruby-deserialization-ox-parse-obj
  Ox.parse_obj(body)
end

def from_xml_const
  # ok: ruby-deserialization-ox-parse-obj
  Ox.parse_obj("<o/>")
end
