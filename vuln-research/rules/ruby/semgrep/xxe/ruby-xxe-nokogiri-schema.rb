# Fixture for the Nokogiri::XML::Schema rule.

require "nokogiri"

def compile(schema_src)
  # ruleid: ruby-xxe-nokogiri-schema
  Nokogiri::XML::Schema(schema_src)
end

def compile_static
  # ok: ruby-xxe-nokogiri-schema
  Nokogiri::XML::Schema("<xs:schema/>")
end
