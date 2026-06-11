# Fixture for the YAML.load_file rule.
# Flagged line loads a file unsafely; safe line constrains permitted classes.

require "yaml"

def load_settings(path)
  # ruleid: ruby-deserialization-yaml-load-file
  YAML.load_file(path)
end

def load_settings_safe(path)
  # ok: ruby-deserialization-yaml-load-file
  YAML.load_file(path, permitted_classes: [Symbol, Date])
end
