# Fixture for the Nokogiri HUGE limits rule.

require "nokogiri"

def parse_huge_block(body)
  Nokogiri::XML(body) do |config|
    # ruleid: ruby-xxe-nokogiri-huge
    config.huge
  end
end

def parse_huge_opt(body)
  # ruleid: ruby-xxe-nokogiri-huge
  Nokogiri::XML(body, nil, nil, Nokogiri::XML::ParseOptions::HUGE)
end

def parse_bounded(body)
  # ok: ruby-xxe-nokogiri-huge
  Nokogiri::XML(body)
end
