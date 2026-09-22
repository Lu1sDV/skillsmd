# Test fixture for rb/ssti-html-escape-wrong-method
# Demonstrates bare (unqualified) html_escape / html_escape_once calls that
# should be flagged vs. ERB::Util-qualified calls that should not be flagged.

module TestHelpers
  def user_email
    "user@example.com<script>"
  end

  def user_input
    "user controlled <b>value</b>"
  end

  # BAD: bare html_escape — no explicit ERB::Util receiver
  def bad_email_display
    html_escape(user_email)
  end

  # BAD: bare html_escape with % format hash (same method, different usage)
  def bad_format_string
    html_escape(_('Hello %{name}, welcome')) % { name: user_input }
  end

  # BAD: bare html_escape_once — same problem, sister method
  def bad_escape_once
    html_escape_once(user_input)
  end

  # GOOD: qualified ERB::Util.html_escape — explicit module receiver, not flagged
  def good_qualified
    ERB::Util.html_escape(user_email)
  end

  # GOOD: qualified ERB::Util.html_escape_once — not flagged
  def good_escape_once_qualified
    ERB::Util.html_escape_once(user_input)
  end

  # GOOD: some_object.html_escape — receiver is not self, not flagged
  def good_explicit_receiver
    some_helper.html_escape(user_email)
  end
end
