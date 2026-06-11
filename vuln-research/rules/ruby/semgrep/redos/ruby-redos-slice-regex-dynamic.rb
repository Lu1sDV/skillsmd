# Fixture for String#slice with a client-supplied regex.
# The flagged lines slice with a params-built regex; the safe line uses a literal.

def cut(text, params)
  # ruleid: ruby-redos-slice-regex-dynamic
  text.slice(Regexp.new(params[:pat]))
end

def cut_bang(text, params)
  # ruleid: ruby-redos-slice-regex-dynamic
  text.slice!(Regexp.new(params[:pat]))
end

def cut_fixed(text)
  # ok: ruby-redos-slice-regex-dynamic
  text.slice(/\A\d+/)
end
