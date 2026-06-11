# Fixture for String#sub with a client-supplied pattern.
# The flagged line substitutes using a params-built regex; the safe line uses a literal.

def rewrite(text, params)
  # ruleid: ruby-redos-sub-dynamic
  text.sub(Regexp.new(params[:head]), "")
end

def rewrite_fixed(text)
  # ok: ruby-redos-sub-dynamic
  text.sub(/\Awww\./, "")
end
