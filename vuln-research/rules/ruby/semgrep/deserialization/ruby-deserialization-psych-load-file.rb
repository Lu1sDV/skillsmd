# Fixture for the Psych.load_file rule.
# Flagged line loads a file unsafely; safe line constrains permitted classes.

require "psych"

def read_manifest(path)
  # ruleid: ruby-deserialization-psych-load-file
  Psych.load_file(path)
end

def read_manifest_safe(path)
  # ok: ruby-deserialization-psych-load-file
  Psych.load_file(path, permitted_classes: [Symbol])
end
