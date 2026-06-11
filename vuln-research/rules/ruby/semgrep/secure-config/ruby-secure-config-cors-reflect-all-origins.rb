# Fixture for the reflect-all CORS origin rule.

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # ruleid: ruby-secure-config-cors-reflect-all-origins
    origins { |source, env| true }
    resource "*"
  end
end

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # ok: ruby-secure-config-cors-reflect-all-origins
    origins { |source, env| ALLOWED.include?(source) }
    resource "*"
  end
end
