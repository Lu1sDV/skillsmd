# Fixture for the Nokogiri DTD-validation rule.

require "nokogiri"

def parse_validate(body)
  Nokogiri::XML(body) do |config|
    # ruleid: ruby-xxe-nokogiri-nonet-missing
    config.dtdvalid
  end
end

def parse_validate_safe(body)
  Nokogiri::XML(body) do |config|
    # ok: ruby-xxe-nokogiri-nonet-missing
    config.strict.nonet
  end
end
