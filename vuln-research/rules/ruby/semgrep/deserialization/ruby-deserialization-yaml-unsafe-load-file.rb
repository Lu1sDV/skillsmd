# Fixture for the YAML.unsafe_load_file rule.
# Flagged line loads a file with the unsafe loader; safe line uses the allowlisted loader.

require "yaml"

def import_dump(path)
  # ruleid: ruby-deserialization-yaml-unsafe-load-file
  YAML.unsafe_load_file(path)
end

def import_dump_safe(path)
  # ok: ruby-deserialization-yaml-unsafe-load-file
  YAML.safe_load_file(path, permitted_classes: [Symbol])
end
