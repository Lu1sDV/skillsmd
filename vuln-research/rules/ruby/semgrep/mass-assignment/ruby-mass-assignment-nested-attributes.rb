# Fixture for the nested-attributes rule.

class Order
  # ruleid: ruby-mass-assignment-nested-attributes
  accepts_nested_attributes_for :line_items, allow_destroy: true
end

class Invoice
  # ok: ruby-mass-assignment-nested-attributes
  accepts_nested_attributes_for :line_items, reject_if: :all_blank
end
