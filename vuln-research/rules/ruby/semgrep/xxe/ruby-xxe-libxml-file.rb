# Fixture for the LibXML file-parse rule.

require "libxml"

def parse_file_opts(path)
  # ruleid: ruby-xxe-libxml-file
  LibXML::XML::Document.file(path, options: LibXML::XML::Parser::Options::DTDLOAD)
end

def parse_file_default(path)
  # ok: ruby-xxe-libxml-file
  LibXML::XML::Document.file(path)
end
