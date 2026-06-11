# Fixture for String#match with a client-supplied pattern.
# The flagged call compiles params into the regex; the safe call uses a constant.

def find(subject, params)
  # ruleid: ruby-redos-match-dynamic
  subject.match(Regexp.new(params[:pattern]))
end

def find_fixed(subject)
  # ok: ruby-redos-match-dynamic
  subject.match(Regexp.new("[0-9]{3}"))
end
