# Fixture for the Pundit authorization-skip detector.

def show
  # ruleid: ruby-auth-session-pundit-skip-authorization
  skip_authorization
  @record = Record.find(params[:id])
end

def index
  # ruleid: ruby-auth-session-pundit-skip-authorization
  skip_policy_scope
  @records = Record.all
end

def edit
  # ok: ruby-auth-session-pundit-skip-authorization
  authorize @record
end
