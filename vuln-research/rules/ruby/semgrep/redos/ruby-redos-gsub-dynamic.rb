# Fixture for String#gsub with a client-supplied pattern.
# The flagged line substitutes using a params-built regex; the safe line uses a literal.

def redact(text, params)
  # ruleid: ruby-redos-gsub-dynamic
  text.gsub(Regexp.new(params[:find]), "***")
end

def redact_fixed(text)
  # ok: ruby-redos-gsub-dynamic
  text.gsub(/\s+/, " ")
end
