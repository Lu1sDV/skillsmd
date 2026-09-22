# Fixture for HamlHtmlSafeInterpolationPercent — tests both the vulnerable and safe shapes.

class HamlViewHelper
  def render_link_start(url)
    # BAD: string literal .html_safe then % with hash — raw HTML inserted
    link_start = '<a href="%{url}">'.html_safe % { url: url }
    link_start
  end

  def render_search_result(link_to_project)
    # BAD: i18n call .html_safe then % with hash — user link inserted raw
    s_('SearchCodeResults|of %{link_to_project}').html_safe % { link_to_project: link_to_project }
  end

  def render_group_result(link_to_group)
    # BAD: _() i18n call .html_safe then % with hash
    _("in group %{link_to_group}").html_safe % { link_to_group: link_to_group }
  end

  def render_link_start_safe(url)
    # GOOD: uses safe_format + tag_pair — properly escaped
    link = link_to('', url)
    safe_format(s_('AdminSettings|Learn more about %{link_start}templates%{link_end}.'), tag_pair(link, :link_start, :link_end))
  end

  def render_safe_percent_on_plain_string(name)
    # GOOD: % on a plain string (not .html_safe) — Rails auto-escaping still active
    "Hello %{name}" % { name: name }
  end

  def render_safe_format_only(link_to_project)
    # GOOD: safe_format without .html_safe % pattern
    safe_format(_("in project %{link_to_project}"), link_to_project: link_to_project)
  end
end
