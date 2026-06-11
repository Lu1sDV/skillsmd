# Fixture for the Marshal.restore rule.
# Flagged lines restore objects from runtime data; the safe line restores a constant.

def load_state(payload)
  # ruleid: ruby-deserialization-marshal-restore
  Marshal.restore(payload)
end

def fixed_state
  # ok: ruby-deserialization-marshal-restore
  Marshal.restore("\x04\b0")
end
