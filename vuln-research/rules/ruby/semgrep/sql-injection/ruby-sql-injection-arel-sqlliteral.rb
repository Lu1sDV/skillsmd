# Fixture exercising Arel::Nodes::SqlLiteral on an interpolated string.

def literal_for(frag)
  # ruleid: ruby-sql-injection-arel-sqlliteral
  Arel::Nodes::SqlLiteral.new("coalesce(#{frag}, 0)")
end

def safe_literal
  # ok: ruby-sql-injection-arel-sqlliteral
  Arel::Nodes::SqlLiteral.new("count(*)")
end
