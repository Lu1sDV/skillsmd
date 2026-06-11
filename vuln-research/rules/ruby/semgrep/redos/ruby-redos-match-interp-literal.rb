# Fixture for String#match with an interpolated regex literal.
# The flagged line interpolates a value into the pattern; the safe line uses a fixed literal.

def find_word(text, params)
  # ruleid: ruby-redos-match-interp-literal
  text.match(/#{params[:term]}+x/)
end

def find_fixed(text)
  # ok: ruby-redos-match-interp-literal
  text.match(/\Aabc\z/)
end
