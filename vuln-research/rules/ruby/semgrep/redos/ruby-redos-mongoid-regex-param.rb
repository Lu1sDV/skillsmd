# Fixture for Mongoid $regex queries fed from request input.
# The flagged query passes params to $regex; the safe query uses a fixed, escaped value.

def lookup(params)
  # ruleid: ruby-redos-mongoid-regex-param
  Account.where(name: { "$regex" => params[:q] })
end

def lookup_fixed(params)
  # ok: ruby-redos-mongoid-regex-param
  Account.where(name: { "$regex" => "\\A#{Regexp.escape(params[:q])}" })
end
