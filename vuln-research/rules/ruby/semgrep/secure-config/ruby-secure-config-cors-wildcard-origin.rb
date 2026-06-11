# Fixture for the wildcard CORS origin rule.

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # ruleid: ruby-secure-config-cors-wildcard-origin
    origins "*"
    resource "*", headers: :any, methods: [:get, :post]
  end
end

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # ok: ruby-secure-config-cors-wildcard-origin
    origins "https://app.example.com"
    resource "*", headers: :any, methods: [:get, :post]
  end
end
