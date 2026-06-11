# Fixture for the authentication-gate skip detector.

class ReportsController < ApplicationController
  # ruleid: ruby-auth-session-skip-authenticate-user
  skip_before_action :authenticate_user!

  def index
  end
end

class PublicController < ApplicationController
  # ok: ruby-auth-session-skip-authenticate-user
  before_action :authenticate_user!
end
