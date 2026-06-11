# Fixture for the CanCanCan authorization-check skip detector.

class WidgetsController < ApplicationController
  # ruleid: ruby-auth-session-cancancan-skip-authorization-check
  skip_authorization_check

  def index
  end
end

class GuardedController < ApplicationController
  # ok: ruby-auth-session-cancancan-skip-authorization-check
  load_and_authorize_resource
end
