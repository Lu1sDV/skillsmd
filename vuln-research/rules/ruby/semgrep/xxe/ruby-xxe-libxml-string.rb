# Fixture for the LibXML string-parse rule.

require "libxml"

def parse_opts(body)
  # ruleid: ruby-xxe-libxml-string
  LibXML::XML::Document.string(body, options: LibXML::XML::Parser::Options::NOENT)
end

def parse_default(body)
  # ok: ruby-xxe-libxml-string
  LibXML::XML::Document.string(body)
end
