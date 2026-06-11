# Fixture for the serialize Marshal-coder rule.
# Flagged lines pick the Marshal coder; safe line uses JSON.

class Account < ApplicationRecord
  # ruleid: ruby-deserialization-serialize-marshal-coder
  serialize :preferences, coder: Marshal

  # ruleid: ruby-deserialization-serialize-marshal-coder
  serialize :legacy_blob, Marshal

  # ok: ruby-deserialization-serialize-marshal-coder
  serialize :settings, coder: JSON
end
