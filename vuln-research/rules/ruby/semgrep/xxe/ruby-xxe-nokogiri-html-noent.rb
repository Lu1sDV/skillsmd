# Fixture for the Nokogiri::HTML NOENT rule.

require "nokogiri"

def parse_html(body)
  # ruleid: ruby-xxe-nokogiri-html-noent
  Nokogiri::HTML(body, nil, nil, Nokogiri::XML::ParseOptions::NOENT)
end

def parse_html_safe(body)
  # ok: ruby-xxe-nokogiri-html-noent
  Nokogiri::HTML(body)
end
