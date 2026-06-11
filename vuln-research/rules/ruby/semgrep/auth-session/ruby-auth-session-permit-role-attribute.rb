# Fixture for the privilege-attribute-in-permit-list detector.

def user_params_admin
  # ruleid: ruby-auth-session-permit-role-attribute
  params.require(:user).permit(:name, :email, :admin)
end

def user_params_role
  # ruleid: ruby-auth-session-permit-role-attribute
  params.require(:user).permit(:name, :role)
end

def user_params_safe
  # ok: ruby-auth-session-permit-role-attribute
  params.require(:user).permit(:name, :email)
end
