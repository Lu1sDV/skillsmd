# Fixture for the skip_forgery_protection detector.

class ApiController < ApplicationController
  # ruleid: ruby-auth-session-skip-forgery-protection
  skip_forgery_protection

  def update
  end
end

class ScopedController < ApplicationController
  # ruleid: ruby-auth-session-skip-forgery-protection
  skip_forgery_protection only: :ingest
end

class GoodController < ApplicationController
  # ok: ruby-auth-session-skip-forgery-protection
  protect_from_forgery with: :exception
end
