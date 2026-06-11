# Fixture for hardcoded http_basic_authenticate_with credentials.
# Flagged declaration inlines name/password; the safe one sources them from the environment.

class ReportsController < ApplicationController
  # ruleid: ruby-hardcoded-secrets-basic-auth-credentials-method
  http_basic_authenticate_with name: "admin", password: "Stat1cAdminPass", only: :index
end

class DashboardController < ApplicationController
  # ok: ruby-hardcoded-secrets-basic-auth-credentials-method
  http_basic_authenticate_with name: ENV["DASH_USER"], password: ENV["DASH_PASS"], only: :index
end
