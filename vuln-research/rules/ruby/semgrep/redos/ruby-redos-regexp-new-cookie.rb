# Fixture for compiling a cookie value into a regex.
# The flagged line builds the regex from a cookie; the safe line uses a constant.

def cookie_filter
  # ruleid: ruby-redos-regexp-new-cookie
  Regexp.new(cookies[:search_rule])
end

def cookie_filter_fixed
  # ok: ruby-redos-regexp-new-cookie
  Regexp.new("\\A[0-9]{4}\\z")
end
