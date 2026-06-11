# Fixture for the prepend_view_path / append_view_path path-injection rule.

def set_theme
  # ruleid: ruby-path-traversal-view-path
  prepend_view_path(params[:theme_dir])
end

def add_theme
  # ruleid: ruby-path-traversal-view-path
  append_view_path("app/themes/#{params[:theme]}")
end

def set_fixed_theme
  # ok: ruby-path-traversal-view-path
  prepend_view_path("app/themes/default")
end
