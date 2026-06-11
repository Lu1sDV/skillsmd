# Fixture for compiling a request parameter into a regex.
# The flagged line passes params straight to Regexp.new; the safe line uses a constant.

def search(params)
  # ruleid: ruby-redos-regexp-new-var
  rx = Regexp.new(params[:pattern])
  rx.match?("input")
end

def constrained_search
  # ok: ruby-redos-regexp-new-var
  rx = Regexp.new("[a-z]+")
  rx.match?("input")
end
