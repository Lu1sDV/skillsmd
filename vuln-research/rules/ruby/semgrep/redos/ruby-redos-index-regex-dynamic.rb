# Fixture for String#[] indexed by a client-supplied regex.
# The flagged line indexes with a params-built regex; the safe line uses a literal.

def grab(text, params)
  # ruleid: ruby-redos-index-regex-dynamic
  text[Regexp.new(params[:pat])]
end

def grab_fixed(text)
  # ok: ruby-redos-index-regex-dynamic
  text[/\A\w+/]
end
