# Fixture exercising Arel NamedFunction with a tainted function name.

def agg(column)
  # ruleid: ruby-sql-injection-arel-named-function
  Arel::Nodes::NamedFunction.new(params[:fn], [column])
end

def safe_agg(column)
  # ok: ruby-sql-injection-arel-named-function
  Arel::Nodes::NamedFunction.new("SUM", [column])
end
