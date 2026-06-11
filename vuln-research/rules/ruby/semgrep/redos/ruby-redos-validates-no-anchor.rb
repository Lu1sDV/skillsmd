# Fixture for unanchored format validations.
# The flagged validation has no string anchors; the safe one anchors with start- and end-of-string.

class Bio
  # ruleid: ruby-redos-validates-no-anchor
  validates :about, format: { with: /[a-z ]+/ }

  # ok: ruby-redos-validates-no-anchor
  validates :slug, format: { with: /\A[a-z]+\z/ }
end
