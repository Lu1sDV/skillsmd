# Fixture for Mustache.render with an interpolated template string.

def greet(user)
  # ruleid: ruby-ssti-mustache-render-interp
  Mustache.render("Hi #{user}, see {{count}} items", count: 3)
end

def greet_safe(user)
  # ok: ruby-ssti-mustache-render-interp
  Mustache.render("Hi {{user}}, see {{count}} items", user: user, count: 3)
end
