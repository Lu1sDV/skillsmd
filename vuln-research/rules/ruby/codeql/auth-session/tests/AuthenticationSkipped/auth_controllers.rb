# Test fixtures for rb/auth-session-authentication-skipped (CWE-306 / CWE-862).

# BAD: skips Devise authenticate_user! on all actions — confirmed in real GitLab diff
# (c34f64202a013bb6460b40c346d05120ab4182b4: CustomersDot::ProxyController).
class ProxyController < ApplicationController
  skip_before_action :authenticate_user!
  def index; end
end

# BAD: legacy filter API, same weakness.
class LegacyApiController < ApplicationController
  skip_before_filter :authenticate_user!
  def show; end
end

# BAD: scoped skip still removes authentication for the listed actions.
class RegistrationsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]
  def new; end
  def create; end
end

# BAD: custom auth callback skipped wholesale.
class InternalController < ApplicationController
  skip_before_action :require_login
  def dashboard; end
end

# BAD: API-style auth callback skipped.
class ApiController < ApplicationController
  skip_before_action :authenticate_request
  def data; end
end

# GOOD: no authentication skip at all.
class AccountsController < ApplicationController
  before_action :authenticate_user!
  def show; end
end

# GOOD: skips a non-authentication callback (rate limiting) — should NOT be flagged.
class WebhooksController < ApplicationController
  skip_before_action :check_rate_limit
  def receive; end
end

# GOOD: skips a CSRF callback — different concern, not authentication.
class ApiUploadsController < ApplicationController
  skip_before_action :verify_authenticity_token
  def create; end
end
