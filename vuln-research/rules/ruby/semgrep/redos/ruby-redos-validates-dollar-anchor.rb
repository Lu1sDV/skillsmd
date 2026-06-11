# Fixture for line-anchored format validations.
# The flagged validation ends with the end-of-line metacharacter; the safe one uses the end-of-string anchor.

class Account
  # ruleid: ruby-redos-validates-dollar-anchor
  validates :name, format: { with: /[a-z]+$/ }

  # ok: ruby-redos-validates-dollar-anchor
  validates :handle, format: { with: /\A[a-z]+\z/ }
end
