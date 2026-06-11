# Fixture for javascript_include_tag with a tainted source.

module ScriptHelper
  def widget_script
    # ruleid: ruby-open-redirect-javascript-include-tag
    javascript_include_tag(params[:widget_url])
  end

  def widget_script_interp(tenant)
    # ruleid: ruby-open-redirect-javascript-include-tag
    javascript_include_tag("https://#{tenant.cdn}/w.js")
  end

  def safe_script
    # ok: ruby-open-redirect-javascript-include-tag
    javascript_include_tag("application")
  end
end
