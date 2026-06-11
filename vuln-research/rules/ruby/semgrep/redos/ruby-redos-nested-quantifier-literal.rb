# Fixture for catastrophic-backtracking literals.
# The flagged literal has a quantified group followed by another quantifier; the safe one is linear.

class Validator
  # ruleid: ruby-redos-nested-quantifier-literal
  EMAIL = /\A([a-z0-9._%+-]+)+@example\.com\z/

  # ok: ruby-redos-nested-quantifier-literal
  HANDLE = /\A[a-z0-9._%+-]+@example\.com\z/
end
