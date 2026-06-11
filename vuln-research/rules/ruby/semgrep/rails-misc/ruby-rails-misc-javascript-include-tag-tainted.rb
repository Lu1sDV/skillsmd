# Fixture for user-controlled script/style includes.

module LayoutHelper
  def widget_script(params)
    # ruleid: ruby-rails-misc-javascript-include-tag-tainted
    javascript_include_tag(params[:src])
  end

  def theme_style(params)
    # ruleid: ruby-rails-misc-javascript-include-tag-tainted
    stylesheet_link_tag(params[:href])
  end

  def core_script
    # ok: ruby-rails-misc-javascript-include-tag-tainted
    javascript_include_tag("application")
  end
end
