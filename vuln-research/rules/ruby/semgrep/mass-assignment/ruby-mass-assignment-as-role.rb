# Fixture for the as-role rule.

def build_as_admin
  # ruleid: ruby-mass-assignment-as-role
  User.new(params[:user], as: :admin)
end

def assign_as_admin(user)
  # ruleid: ruby-mass-assignment-as-role
  user.assign_attributes(params[:user], as: :admin)
end

def build_default_role
  # ok: ruby-mass-assignment-as-role
  User.new(params.require(:user).permit(:name))
end
