# Fixture for the null_session forgery-protection detector.

class WeakController < ApplicationController
  # ruleid: ruby-auth-session-protect-from-forgery-null-session
  protect_from_forgery with: :null_session
end

class StrongController < ApplicationController
  # ok: ruby-auth-session-protect-from-forgery-null-session
  protect_from_forgery with: :exception
end
