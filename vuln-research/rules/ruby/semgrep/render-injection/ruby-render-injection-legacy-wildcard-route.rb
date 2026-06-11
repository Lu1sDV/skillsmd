# Fixture mimicking a routes file with a dynamic segment mapping.

Rails.application.routes.draw do
  # ruleid: ruby-render-injection-legacy-wildcard-route
  match ":controller(/:action(/:id(.:format)))", via: :all

  # ok: ruby-render-injection-legacy-wildcard-route
  get "/articles/:id", to: "articles#show"
end
