# Fixture for the libxml-ruby global-default options rule.

require "libxml"

def enable_entities
  # ruleid: ruby-xxe-libxml-default-options
  LibXML::XML.default_substitute_entities = true
end

def keep_default
  # ok: ruby-xxe-libxml-default-options
  LibXML::XML.default_substitute_entities = false
end
