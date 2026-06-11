# Fixture for the no-op verify_authenticity_token override detector.

class SneakyController < ApplicationController
  # ruleid: ruby-auth-session-verify-authenticity-token-override
  def verify_authenticity_token
  end
end

class NormalController < ApplicationController
  # ok: ruby-auth-session-verify-authenticity-token-override
  def verify_authenticity_token
    super
  end
end
