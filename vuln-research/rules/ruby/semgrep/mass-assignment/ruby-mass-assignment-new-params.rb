# Fixture for the new-params rule.
# The flagged constructor call below takes a raw request slice; the permitted
# variant beneath it is the safe form.

def build_user
  # ruleid: ruby-mass-assignment-new-params
  User.new(params[:user])
end

def build_account
  # ruleid: ruby-mass-assignment-new-params
  Account.new(params[:account], created_by: current_user)
end

def build_user_safe
  # ok: ruby-mass-assignment-new-params
  User.new(params.require(:user).permit(:name, :email))
end

def build_from_literal
  # ok: ruby-mass-assignment-new-params
  User.new(name: "alice", email: "a@example.com")
end
