# Fixture for the Regexp.new interpolation rule.
# The flagged line builds a pattern from a runtime value; the safe line uses a literal.

def filter(term)
  # ruleid: ruby-redos-regexp-new-interp
  Regexp.new("^prefix-#{term}.*$")
end

def static_filter
  # ok: ruby-redos-regexp-new-interp
  Regexp.new("\\Aprefix-[a-z0-9]+\\z")
end
