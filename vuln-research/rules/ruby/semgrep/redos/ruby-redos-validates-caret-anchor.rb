# Fixture for start-of-line anchored format validations.
# The flagged validation starts with the start-of-line metacharacter; the safe one uses the start-of-string anchor.

class Profile
  # ruleid: ruby-redos-validates-caret-anchor
  validates :slug, format: { with: /^[a-z0-9-]+/ }

  # ok: ruby-redos-validates-caret-anchor
  validates :code, format: { with: /\A[A-Z0-9]+\z/ }
end
