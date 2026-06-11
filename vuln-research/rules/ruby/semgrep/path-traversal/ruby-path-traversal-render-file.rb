# Fixture for the Rails render file:/template: path-injection rule.

def show_doc
  # ruleid: ruby-path-traversal-render-file
  render(file: params[:doc])
end

def show_template
  # ruleid: ruby-path-traversal-render-file
  render(template: "reports/#{params[:name]}")
end

def show_fixed
  # ok: ruby-path-traversal-render-file
  render(template: "reports/summary")
end
