# Fixture for gsub with an interpolated regex literal.
# The flagged line interpolates a value into the pattern; the safe line uses a fixed literal.

def strip_term(text, params)
  # ruleid: ruby-redos-gsub-interp-literal
  text.gsub(/#{params[:word]}+/, "")
end

def strip_fixed(text)
  # ok: ruby-redos-gsub-interp-literal
  text.gsub(/\s+/, " ")
end
