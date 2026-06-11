# Fixture for the Nokogiri DEFAULT_XML-with-NOENT option rule.

require "nokogiri"

def parse_preset(body)
  # ruleid: ruby-xxe-nokogiri-default-xml-option
  Nokogiri::XML(body, nil, nil, Nokogiri::XML::ParseOptions::DEFAULT_XML | Nokogiri::XML::ParseOptions::NOENT)
end

def parse_plain(body)
  # ok: ruby-xxe-nokogiri-default-xml-option
  Nokogiri::XML(body, nil, nil, Nokogiri::XML::ParseOptions::DEFAULT_XML)
end
