# Fixture for the Ox.load rule.

require "ox"

def materialize(body)
  # ruleid: ruby-xxe-ox-load
  Ox.load(body, mode: :object)
end

def materialize_default(body)
  # ruleid: ruby-xxe-ox-load
  Ox.load(body)
end

def as_hash(body)
  # ok: ruby-xxe-ox-load
  Ox.load(body, mode: :hash)
end
