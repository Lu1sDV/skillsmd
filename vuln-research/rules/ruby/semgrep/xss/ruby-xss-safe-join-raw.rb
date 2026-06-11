# Fixture covering safe_join over pre-marked raw elements.

def list(items)
  # ruleid: ruby-xss-safe-join-raw
  safe_join(items.map { |i| raw(i) })
end

def rows(cells)
  # ruleid: ruby-xss-safe-join-raw
  safe_join(cells.map { |c| "<td>#{c}</td>".html_safe })
end

def plain_list(items)
  # ok: ruby-xss-safe-join-raw
  safe_join(items, ", ")
end
