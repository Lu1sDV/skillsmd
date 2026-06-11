# Fixture for the PStore rule.
# Flagged line opens a store at a runtime path; safe line uses a fixed literal path.

require "pstore"

def open_store(path)
  # ruleid: ruby-deserialization-pstore-marshal
  PStore.new(path)
end

def open_fixed_store
  # ok: ruby-deserialization-pstore-marshal
  PStore.new("/var/lib/app/state.pstore")
end
