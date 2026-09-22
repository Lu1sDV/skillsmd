# Fixture for ControllerMissingAuthzGuard
#
# BAD cases (should be flagged — mutating actions, zero auth/authz before_action)
# GOOD cases (should NOT be flagged)

# BAD: has create + update + destroy, no auth/authz before_action at all
class OrdersController < ApplicationController
  def index
    @orders = Order.all
  end

  def show
    @order = Order.find(params[:id])
  end

  def create
    @order = Order.new(order_params)
    @order.save
  end

  def update
    @order = Order.find(params[:id])
    @order.update(order_params)
  end

  def destroy
    Order.find(params[:id]).destroy
  end
end

# BAD: has create, only non-auth before_action present (verify_import_enabled is not auth)
class Import::WidgetsController < ApplicationController
  before_action :verify_import_enabled

  def index
    render json: {}
  end

  def create
    Widget.create!(widget_params)
  end
end

# GOOD: has create/update/destroy but authenticate_user! before_action is present
class ProjectsController < ApplicationController
  before_action :authenticate_user!

  def index
    @projects = Project.all
  end

  def create
    @project = Project.new(project_params)
    @project.save
  end

  def update
    @project = Project.find(params[:id])
    @project.update(project_params)
  end

  def destroy
    Project.find(params[:id]).destroy
  end
end

# GOOD: read-only controller — only index and show, no mutating actions
class ReportsController < ApplicationController
  def index
    @reports = Report.all
  end

  def show
    @report = Report.find(params[:id])
  end
end

# GOOD: has destroy but protected by authorize_admin! before_action
class Admin::UsersController < ApplicationController
  before_action :authorize_admin!

  def index
    @users = User.all
  end

  def destroy
    User.find(params[:id]).destroy
  end
end

# GOOD: has update protected by require_login before_action
class SettingsController < ApplicationController
  before_action :require_login

  def show
    render :show
  end

  def update
    current_user.update(settings_params)
  end
end
