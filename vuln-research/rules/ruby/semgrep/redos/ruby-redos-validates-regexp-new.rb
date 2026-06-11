# Fixture for validations whose pattern is compiled from request input.
# The flagged validation builds its regex from params; the safe one uses a constant.

class Rule
  # ruleid: ruby-redos-validates-regexp-new
  validates :value, format: { with: Regexp.new(params[:pattern]) }

  # ok: ruby-redos-validates-regexp-new
  validates :value, format: { with: /\A[a-z]+\z/ }
end
