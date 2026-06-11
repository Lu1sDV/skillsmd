# Fixture for ActionView::Template built from an interpolated source string.

def compile_view(fragment)
  # ruleid: ruby-ssti-actionview-template-interp
  ActionView::Template.new("<p>#{fragment}</p>", "inline", handler, {})
end

def compile_view_safe
  # ok: ruby-ssti-actionview-template-interp
  ActionView::Template.new("<p><%= fragment %></p>", "inline", handler, {})
end
