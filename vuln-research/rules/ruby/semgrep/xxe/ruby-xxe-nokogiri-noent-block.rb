# Fixture for the Nokogiri config-block entity rule.
# The block that turns on entity substitution is flagged; the hardened one is not.

require "nokogiri"

def parse_block(body)
  Nokogiri::XML(body) do |config|
    # ruleid: ruby-xxe-nokogiri-noent-block
    config.noent
  end
end

def parse_block_safe(body)
  Nokogiri::XML(body) do |config|
    # ok: ruby-xxe-nokogiri-noent-block
    config.strict.nononet
  end
end
