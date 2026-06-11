# Fixture for the Nori.parse rule.

require "nori"

def soap_in(body)
  # ruleid: ruby-xxe-nori-parse
  Nori.new(strip_namespaces: true).parse(body)
end

def soap_static
  # ok: ruby-xxe-nori-parse
  Nori.parse("<Envelope/>")
end
