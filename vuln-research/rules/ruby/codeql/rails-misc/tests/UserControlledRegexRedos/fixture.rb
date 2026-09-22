# BAD: Regexp.new with a dynamic (non-literal) argument — no UntrustedRegexp guard
def filter_refs_bad(refs, term)
  regex_string = Regexp.quote(term.downcase)
  regex = Regexp.new(regex_string)
  refs.select { |ref| regex === ref.name }
end

# BAD: interpolated regex literal with a dynamic #{} component — no UntrustedRegexp guard
def filter_refs_interp_bad(refs, term)
  refs.select { |ref| /#{term}/ === ref.name }
end

# GOOD: uses Gitlab::UntrustedRegexp in the same method — safe wrapper present
def filter_refs_good(refs, term)
  escaped = RE2::Regexp.escape(term.downcase)
  regex = Gitlab::UntrustedRegexp.new(escaped)
  refs.select { |ref| regex.match?(ref.name) }
end

# GOOD: Regexp.new with a plain string literal — not user-controlled
def build_static_regex
  r = Regexp.new("^feature_branch$")
  r
end

# GOOD: interpolated regex literal but UntrustedRegexp used in same method
def filter_safe_interp(refs, term)
  safe = Gitlab::UntrustedRegexp.new(RE2::Regexp.escape(term))
  refs.select { |ref| /#{term}/ === ref.name }
end
