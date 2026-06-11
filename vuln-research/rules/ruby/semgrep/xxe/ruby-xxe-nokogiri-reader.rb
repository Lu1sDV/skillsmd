# Fixture for the Nokogiri::XML::Reader rule.

require "nokogiri"

def stream(body)
  # ruleid: ruby-xxe-nokogiri-reader
  Nokogiri::XML::Reader(body, nil, nil, Nokogiri::XML::ParseOptions::NOENT)
end

def stream_safe(body)
  # ok: ruby-xxe-nokogiri-reader
  Nokogiri::XML::Reader(body)
end
