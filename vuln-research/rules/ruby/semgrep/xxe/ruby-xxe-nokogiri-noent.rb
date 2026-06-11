# Fixture for the Nokogiri NOENT parse-option rule.
# The flagged calls enable entity substitution; the final call leaves it off.

require "nokogiri"

def parse_with_noent(body)
  # ruleid: ruby-xxe-nokogiri-noent
  Nokogiri::XML(body, nil, nil, Nokogiri::XML::ParseOptions::NOENT)
end

def parse_doc_with_noent(body)
  # ruleid: ruby-xxe-nokogiri-noent
  Nokogiri::XML::Document.parse(body, nil, nil, Nokogiri::XML::ParseOptions::NOENT)
end

def parse_default(body)
  # ok: ruby-xxe-nokogiri-noent
  Nokogiri::XML(body)
end
