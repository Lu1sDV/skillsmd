# Test fixtures for rb/auth-session-overly-broad-authz-skip (CWE-285).
# Grounded in real GitLab diffs (shas 30cc4e834c30, d7ffe0b5a8e4):
#   before fix: skip_before_action :authorize_admin_group!, only: [:edit, :update]
#   after  fix: skip_before_action :authorize_admin_group!, only: [:edit]

# BAD: authorize_admin_group! skipped for :update (mutating) — grounded in real GitLab diff.
class GroupsController < ApplicationController
  skip_before_action :authorize_admin_group!, only: [:edit, :update]
  def edit; end
  def update; end
end

# BAD: authorize_admin_project! skipped for :destroy — privilege escalation on destroy.
class ProjectsController < ApplicationController
  skip_before_action :authorize_admin_project!, only: [:show, :destroy]
  def show; end
  def destroy; end
end

# BAD: authorize_owner_resource! skipped for :create — owner authz skipped on creation.
class ResourcesController < ApplicationController
  skip_before_action :authorize_owner_resource!, only: [:create, :index]
  def create; end
  def index; end
end

# BAD: legacy skip_before_filter alias, authorize_admin_billing! skipped for :edit.
class BillingController < ApplicationController
  skip_before_filter :authorize_admin_billing!, only: [:edit]
  def edit; end
end

# GOOD: only: contains read-only actions [:show, :index] — no mutating action, not flagged.
class PagesController < ApplicationController
  skip_before_action :authorize_admin_group!, only: [:show, :index]
  def show; end
  def index; end
end

# GOOD: non-authorization callback skipped (rate limiting) — pattern does not match authz.
class WebhooksController < ApplicationController
  skip_before_action :check_rate_limit, only: [:create, :update]
  def create; end
  def update; end
end

# GOOD: authentication callback skipped (different concern — caught by a separate query).
class ApiController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]
  def index; end
end

# GOOD: no only: keyword arg at all — conservative, not flagged (no array to inspect).
class AdminController < ApplicationController
  skip_before_action :authorize_admin_settings!
  def index; end
end
