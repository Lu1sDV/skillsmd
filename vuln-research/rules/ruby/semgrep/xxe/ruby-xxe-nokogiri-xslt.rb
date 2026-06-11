# Fixture for the Nokogiri::XSLT rule.

require "nokogiri"

def transform(stylesheet)
  # ruleid: ruby-xxe-nokogiri-xslt
  Nokogiri::XSLT(stylesheet)
end

def transform_static
  # ok: ruby-xxe-nokogiri-xslt
  Nokogiri::XSLT("<xsl:stylesheet/>")
end
