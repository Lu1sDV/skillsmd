# Fixture covering asset tag helpers with attacker-controlled URLs.

def dynamic_js
  # ruleid: ruby-xss-stylesheet-link-src
  javascript_include_tag(params[:script_url])
end

def dynamic_css
  # ruleid: ruby-xss-stylesheet-link-src
  stylesheet_link_tag(params[:theme_url])
end

def fixed_assets
  # ok: ruby-xss-stylesheet-link-src
  javascript_include_tag("application")
end
