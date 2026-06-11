# Fixture for the Nokogiri config-block DTD-loading rule.

require "nokogiri"

def parse_dtd(body)
  Nokogiri::XML(body) do |config|
    # ruleid: ruby-xxe-nokogiri-dtdload-block
    config.dtdload
  end
end

def parse_dtd_safe(body)
  Nokogiri::XML(body) do |config|
    # ok: ruby-xxe-nokogiri-dtdload-block
    config.nonet
  end
end
