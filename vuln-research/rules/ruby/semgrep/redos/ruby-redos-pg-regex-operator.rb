# Fixture for PostgreSQL regex-operator search filters.
# The flagged query binds a value to the ~ operator; the safe query uses a LIKE literal.

def search(params)
  # ruleid: ruby-redos-pg-regex-operator
  User.where("name ~ ?", params[:pattern])
end

def search_like(params)
  # ok: ruby-redos-pg-regex-operator
  User.where("name LIKE ?", "%#{params[:term]}%")
end
