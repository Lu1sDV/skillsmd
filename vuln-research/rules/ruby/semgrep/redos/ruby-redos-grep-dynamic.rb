# Fixture for Enumerable#grep with a client-supplied pattern.
# The flagged line filters with a params-built regex; the safe line uses a literal.

def select_lines(lines, params)
  # ruleid: ruby-redos-grep-dynamic
  lines.grep(Regexp.new(params[:filter]))
end

def reject_lines(lines, params)
  # ruleid: ruby-redos-grep-dynamic
  lines.grep_v(Regexp.new(params[:filter]))
end

def select_fixed(lines)
  # ok: ruby-redos-grep-dynamic
  lines.grep(/\Aerror:/)
end
