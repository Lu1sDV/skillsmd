# Fixture for the =~ operator with a client-supplied pattern.
# The flagged line matches against a params-built regex; the safe line uses a constant.

def hit?(text, params)
  # ruleid: ruby-redos-tilde-dynamic
  text =~ Regexp.new(params[:q])
end

def hit_fixed?(text)
  # ok: ruby-redos-tilde-dynamic
  text =~ Regexp.new("[a-f0-9]{6}")
end
