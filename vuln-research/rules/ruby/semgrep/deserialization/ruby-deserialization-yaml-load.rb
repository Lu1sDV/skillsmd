# Fixture for the YAML.load rule.
# Flagged lines parse external YAML; safe lines pin permitted classes or a literal.

require "yaml"

def import_config(body)
  # ruleid: ruby-deserialization-yaml-load
  YAML.load(body)
end

def restricted(body)
  # ok: ruby-deserialization-yaml-load
  YAML.load(body, permitted_classes: [Symbol])
end

def constant_doc
  # ok: ruby-deserialization-yaml-load
  YAML.load("---\nfoo: 1\n")
end
