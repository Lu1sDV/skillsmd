# Fixture for compiling a request header into a regex.
# The flagged line builds the regex from a header; the safe line uses a constant.

def header_filter
  # ruleid: ruby-redos-regexp-new-request-header
  Regexp.new(request.headers["X-Filter"])
end

def header_filter_fixed
  # ok: ruby-redos-regexp-new-request-header
  Regexp.new("\\Aapplication/json\\z")
end
