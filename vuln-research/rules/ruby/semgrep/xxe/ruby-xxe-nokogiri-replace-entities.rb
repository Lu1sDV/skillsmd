# Fixture for the Nokogiri replace_entities rule.

require "nokogiri"

def configure(doc)
  # ruleid: ruby-xxe-nokogiri-replace-entities
  doc.replace_entities = true
end

def configure_safe(doc)
  # ok: ruby-xxe-nokogiri-replace-entities
  doc.replace_entities = false
end
