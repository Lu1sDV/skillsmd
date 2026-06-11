# Fixture exercising interpolated order / reorder clauses.

def sorted(col)
  # ruleid: ruby-sql-injection-order-interp
  Product.order("#{col} DESC")
end

def resorted(col)
  # ruleid: ruby-sql-injection-order-interp
  Product.reorder("#{col} ASC")
end

def safe_sorted
  # ok: ruby-sql-injection-order-interp
  Product.order(created_at: :desc)
end
