# Fixture for the create-bang-params rule.

def make_invoice
  # ruleid: ruby-mass-assignment-create-bang-params
  Invoice.create!(params[:invoice])
end

def make_order
  # ruleid: ruby-mass-assignment-create-bang-params
  Order.create!(params[:order], shop: current_shop)
end

def make_invoice_safe
  # ok: ruby-mass-assignment-create-bang-params
  Invoice.create!(params.require(:invoice).permit(:amount, :due_on))
end

def make_from_literal
  # ok: ruby-mass-assignment-create-bang-params
  Invoice.create!(amount: 10)
end
