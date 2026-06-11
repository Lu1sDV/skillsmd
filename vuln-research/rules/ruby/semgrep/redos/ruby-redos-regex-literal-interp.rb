# Fixture for interpolated regex literals.
# The flagged line splices a value into the pattern; the safe line is a fixed literal.

def matches?(needle, haystack)
  # ruleid: ruby-redos-regex-literal-interp
  haystack =~ /^#{needle}+$/
end

def fixed_match(haystack)
  # ok: ruby-redos-regex-literal-interp
  haystack =~ /\A[a-z]+\z/
end
