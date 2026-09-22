# Test fixture for rb/ssti-html-escape-unqualified
# Demonstrates the unqualified html_escape + % hash pattern (XSS, CWE-79)

module TestHelpers
  def user_input
    "user controlled <script>"
  end

  # BAD: bare html_escape as receiver of % with hash — format happens after escape
  def bad_message_1
    html_escape(_('Hello %{name}')) % { name: user_input }
  end

  # BAD: bare html_escape with multiple substitution keys
  def bad_message_2
    html_escape(_('Welcome %{user}, you have %{count} messages')) % { user: user_input, count: some_count }
  end

  # GOOD: qualified ERB::Util.html_escape — not flagged (explicit module receiver)
  def good_qualified
    ERB::Util.html_escape(_('Hello %{name}')) % { name: user_input }
  end

  # GOOD: html_escape with no % call — not flagged (no format substitution)
  def good_no_percent
    html_escape(user_input)
  end

  # GOOD: % with a literal-only hash (no variable values) and no html_escape
  def good_literal_hash
    some_string % { key: "literal value" }
  end
end
