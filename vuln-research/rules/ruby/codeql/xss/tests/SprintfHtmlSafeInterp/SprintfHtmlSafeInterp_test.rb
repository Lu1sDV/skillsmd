# Fixture for SprintfHtmlSafeInterp — tests both the vulnerable and safe shapes.

class UserProfileHelper
  def render_pronunciation(user)
    # BAD: user-controlled user.pronunciation interpolated into i18n string then marked html_safe
    sprintf(s_("UserProfile|Pronounced as: %{pronunciation}"), { pronunciation: user.pronunciation }).html_safe
  end

  def confirm_user_message(user)
    # BAD: user email (non-constant) interpolated via sprintf/_() then marked html_safe
    sprintf(_('Unconfirmed email: %{email}. Please confirm.'), { email: user.unconfirmed_email }).html_safe
  end

  def render_hardcoded(user)
    # GOOD: all interpolated values are hard-coded string literals — no user data
    sprintf(s_("UserProfile|Role: %{role}"), { role: "member" }).html_safe
  end

  def render_safe_format(user)
    # GOOD: uses safe_format which escapes values before marking safe
    safe_format(s_("UserProfile|Pronouns: %{pronouns}"), pronouns: user.pronouns)
  end

  def render_escaped_individually(user)
    # GOOD: value is explicitly html_escape'd before interpolation — not .html_safe on the sprintf result
    html_escape(user.pronouns)
  end
end
