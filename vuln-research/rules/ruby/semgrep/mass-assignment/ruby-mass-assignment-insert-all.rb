# Fixture for the insert-all rule.

def bulk_insert
  # ruleid: ruby-mass-assignment-insert-all
  LineItem.insert_all(params[:line_items])
end

def bulk_insert_strict
  # ruleid: ruby-mass-assignment-insert-all
  LineItem.insert_all!(params[:line_items])
end

def bulk_insert_safe
  rows = params.require(:line_items).map { |li| li.permit(:sku, :qty).to_h }
  # ok: ruby-mass-assignment-insert-all
  LineItem.insert_all(rows)
end
