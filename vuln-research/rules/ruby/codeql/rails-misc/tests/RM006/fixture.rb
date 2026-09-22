# Fixture for RM006 – YAML.safe_load without bytesize guard

module Config
  class Loader
    # BAD: YAML.safe_load called directly on raw input with no bytesize check.
    # A malicious YAML document with deeply nested anchors can exhaust memory.
    def parse_unsafe(raw)
      YAML.safe_load(raw, permitted_classes: [Symbol])
    end

    # BAD: Psych.safe_load variant – same issue, no bytesize guard.
    def parse_psych_unsafe(raw)
      Psych.safe_load(raw)
    end

    # GOOD: bytesize checked before YAML.safe_load – not flagged.
    def parse_safe(raw)
      raise DataTooLargeError, "YAML too large" if raw.bytesize > MAX_YAML_SIZE
      YAML.safe_load(raw, permitted_classes: [Symbol])
    end

    # GOOD: bytesize checked before Psych.safe_load – not flagged.
    def parse_psych_safe(raw)
      raise ArgumentError, "too large" if raw.bytesize > 1_000_000
      Psych.safe_load(raw)
    end
  end
end
