# Fixture for Regexp.new with options whose pattern is a request parameter.
# The flagged line compiles params with a flag; the safe line compiles a literal with a flag.

def ci_match(params)
  # ruleid: ruby-redos-regexp-new-options-param
  Regexp.new(params[:pattern], Regexp::IGNORECASE)
end

def ci_match_fixed
  # ok: ruby-redos-regexp-new-options-param
  Regexp.new("[a-z]+", Regexp::IGNORECASE)
end
