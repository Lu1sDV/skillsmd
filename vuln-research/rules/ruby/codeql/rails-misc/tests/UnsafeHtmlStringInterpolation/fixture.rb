# frozen_string_literal: true

module HelpersExample
  # BAD: html_safe marks the translation string safe, then % interpolates
  # user-controlled content without escaping — raw HTML/JS can reach the browser.
  def bad_unconfirmed_message(email)
    _('This user has an unconfirmed email address (%{email}). You may force a confirmation.') \
      .html_safe % { email: email }
  end

  # BAD: multi-line form — same vulnerability
  def bad_svn_message(svn_link)
    _('To connect an SVN repository, check out %{svn_link}.').html_safe % { svn_link: svn_link }
  end

  # GOOD: safe_format escapes each interpolated slot before composing the result.
  def good_unconfirmed_message(email)
    safe_format(_('This user has an unconfirmed email address (%{email}). You may force a confirmation.'), email: email)
  end

  # GOOD: plain % on a non-html_safe string is fine (no html_safe in the chain).
  def good_plain_format(name)
    'Hello %{name}' % { name: name }
  end
end
