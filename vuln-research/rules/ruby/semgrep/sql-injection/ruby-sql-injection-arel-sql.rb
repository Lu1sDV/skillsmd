# Fixture exercising Arel.sql on an interpolated string.

def order_expr(dir)
  # ruleid: ruby-sql-injection-arel-sql
  Item.order(Arel.sql("name #{dir}"))
end

def safe_order_expr
  # ok: ruby-sql-injection-arel-sql
  Item.order(Arel.sql("name ASC"))
end
