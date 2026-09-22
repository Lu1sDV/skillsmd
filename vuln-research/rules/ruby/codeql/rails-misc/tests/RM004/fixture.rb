# frozen_string_literal: true

# BAD: character class with + quantifier — catastrophic backtracking on crafted input
LINK_PATTERN = %r{https?://[^\s>]+}  # BAD: [^\s>]+ is unbounded

# BAD: capturing group with * quantifier — exponential backtracking
EMAIL_RE = /([a-z0-9]+)*@example\.com/  # BAD: ([a-z0-9]+)* is unbounded (nested quantifier)

# GOOD: bounded quantifier — upper limit prevents backtracking
LINK_SAFE = %r{https?://[^\s>]{1,2000}}  # GOOD: bounded with {1,2000}

# GOOD: simple \d+ without character class or group — not flagged (single token, low ReDoS risk)
SIMPLE_NUM = /\d+/  # GOOD: no character class or group operand
