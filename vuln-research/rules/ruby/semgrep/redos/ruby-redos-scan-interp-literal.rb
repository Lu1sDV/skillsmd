# Fixture for String#scan with an interpolated regex literal.
# The flagged line interpolates a value into the pattern; the safe line uses a fixed literal.

def tally(text, params)
  # ruleid: ruby-redos-scan-interp-literal
  text.scan(/#{params[:tok]}+/)
end

def tally_fixed(text)
  # ok: ruby-redos-scan-interp-literal
  text.scan(/\w+/)
end
