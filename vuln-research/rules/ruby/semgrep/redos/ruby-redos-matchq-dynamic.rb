# Fixture for String#match? with a client-supplied pattern.
# The flagged call compiles params into the regex; the safe call uses a constant.

def valid?(subject, params)
  # ruleid: ruby-redos-matchq-dynamic
  subject.match?(Regexp.new(params[:rule]))
end

def valid_fixed?(subject)
  # ok: ruby-redos-matchq-dynamic
  subject.match?(Regexp.new("\\A\\d+\\z"))
end
