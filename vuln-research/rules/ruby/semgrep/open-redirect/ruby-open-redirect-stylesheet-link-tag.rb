# Fixture for stylesheet_link_tag with a tainted href.

module ThemeHelper
  def tenant_theme
    # ruleid: ruby-open-redirect-stylesheet-link-tag
    stylesheet_link_tag(params[:theme_url])
  end

  def tenant_theme_interp(tenant)
    # ruleid: ruby-open-redirect-stylesheet-link-tag
    stylesheet_link_tag("https://#{tenant.cdn}/theme.css")
  end

  def safe_theme
    # ok: ruby-open-redirect-stylesheet-link-tag
    stylesheet_link_tag("application")
  end
end
