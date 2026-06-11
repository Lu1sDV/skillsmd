# Fixture exercising an interpolated LIKE pattern.

def search(q)
  # ruleid: ruby-sql-injection-like-interp
  Article.where("title LIKE '%#{q}%'")
end

def safe_search(q)
  # ok: ruby-sql-injection-like-interp
  Article.where("title LIKE ?", "%#{q}%")
end
