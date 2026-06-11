# Fixture for the permit-sensitive rule.

def user_params
  # ruleid: ruby-mass-assignment-permit-sensitive
  params.require(:user).permit(:name, :admin, :email)
end

def membership_params
  # ruleid: ruby-mass-assignment-permit-sensitive
  params.require(:membership).permit(:account_id, :title)
end

def safe_user_params
  # ok: ruby-mass-assignment-permit-sensitive
  params.require(:user).permit(:name, :email, :bio)
end
