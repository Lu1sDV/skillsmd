# Fixture covering render inline template compilation.

def greet(name)
  # ruleid: ruby-xss-render-inline
  render inline: "Hello #{name}"
end

def greet_param
  # ruleid: ruby-xss-render-inline
  render inline: params[:tmpl]
end

def fixed_template
  # ok: ruby-xss-render-inline
  render inline: "Hello world"
end

def by_file
  # ok: ruby-xss-render-inline
  render template: "users/show", locals: { name: params[:name] }
end
