# Test fixtures for rb/auth-session-csrf-protection-disabled (CWE-352).

# BAD: skips the CSRF token check on a state-changing controller.
class ApiUploadsController < ApplicationController
  skip_before_action :verify_authenticity_token
  def create; end
end

# BAD: legacy filter API, same weakness.
class LegacyHooksController < ApplicationController
  skip_before_filter :verify_authenticity_token
  def receive; end
end

# BAD: null_session silently drops the session instead of rejecting forged requests.
class WebhookController < ApplicationController
  protect_from_forgery with: :null_session
  def callback; end
end

# BAD: skip_forgery_protection turns CSRF off entirely for this controller.
class PaymentsController < ApplicationController
  skip_forgery_protection
  def charge; end
end

# GOOD: CSRF protection enabled and configured to raise on forged requests.
class AccountsController < ApplicationController
  protect_from_forgery with: :exception
  def update; end
end

# GOOD: a plain controller with no CSRF-related calls at all.
class HealthController < ApplicationController
  def show; end
end

# GOOD: skips an UNRELATED before_action, not the CSRF token check.
class DashboardController < ApplicationController
  skip_before_action :require_login
  def index; end
end
