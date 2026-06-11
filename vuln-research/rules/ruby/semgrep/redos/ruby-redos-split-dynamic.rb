# Fixture for String#split with a client-supplied delimiter pattern.
# The flagged line splits on a params-built regex; the safe line uses a literal.

def tokenize(line, params)
  # ruleid: ruby-redos-split-dynamic
  line.split(Regexp.new(params[:sep]))
end

def tokenize_fixed(line)
  # ok: ruby-redos-split-dynamic
  line.split(/,\s*/)
end
