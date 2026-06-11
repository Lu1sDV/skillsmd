# Fixture for compiling request.params into a regex.
# The flagged lines build the regex from the request; the safe line uses a constant.

def req_filter
  # ruleid: ruby-redos-regexp-new-request-params
  Regexp.new(request.params["filter"])
end

def query_filter
  # ruleid: ruby-redos-regexp-new-request-params
  Regexp.new(request.query_parameters["q"])
end

def req_filter_fixed
  # ok: ruby-redos-regexp-new-request-params
  Regexp.new("\\A[a-z]+\\z")
end
