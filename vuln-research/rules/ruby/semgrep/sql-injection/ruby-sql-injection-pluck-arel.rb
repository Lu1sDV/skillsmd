# Fixture exercising pluck with an interpolated Arel.sql fragment.

def values_of(col)
  # ruleid: ruby-sql-injection-pluck-arel
  Product.pluck(Arel.sql("#{col}"))
end

def safe_values
  # ok: ruby-sql-injection-pluck-arel
  Product.pluck(:name)
end
