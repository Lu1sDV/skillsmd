# Fixture for Regexp.union built from request input.
# The flagged line unions a params value; the safe line unions fixed literals.

def build(params)
  # ruleid: ruby-redos-regexp-union-dynamic
  Regexp.union(params[:patterns])
end

def build_fixed
  # ok: ruby-redos-regexp-union-dynamic
  Regexp.union(/\Afoo\z/, /\Abar\z/)
end
