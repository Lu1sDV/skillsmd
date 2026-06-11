# Fixture for the REXML::Document.new rule.

require "rexml/document"

def from_params
  # ruleid: ruby-xxe-rexml-document
  REXML::Document.new(params[:xml])
end

def from_body
  # ruleid: ruby-xxe-rexml-document
  REXML::Document.new(request.body.read)
end

def from_literal
  # ok: ruby-xxe-rexml-document
  REXML::Document.new("<root><a>1</a></root>")
end
