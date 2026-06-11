# Fixture for the YAML.load_stream rule.
# Flagged line parses an external multi-doc stream; safe line uses a literal stream.

require "yaml"

def each_record(stream)
  # ruleid: ruby-deserialization-yaml-load-stream
  YAML.load_stream(stream)
end

def fixed_stream
  # ok: ruby-deserialization-yaml-load-stream
  YAML.load_stream("---\na: 1\n---\nb: 2\n")
end
