# Fixture for the REXML streaming/tree parser rule.

require "rexml/parsers/streamparser"
require "rexml/parsers/sax2parser"

def stream(body, listener)
  # ruleid: ruby-xxe-rexml-stream-parser
  REXML::Parsers::StreamParser.new(body, listener)
end

def sax(body)
  # ruleid: ruby-xxe-rexml-stream-parser
  REXML::Parsers::SAX2Parser.new(body)
end

def build_doc(body)
  # ok: ruby-xxe-rexml-stream-parser
  REXML::Document.new(body)
end
