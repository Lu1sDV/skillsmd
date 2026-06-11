# Fixture for the permit-bang rule.

def user_params
  # ruleid: ruby-mass-assignment-permit-bang
  params.permit!
end

def settings_params
  # ruleid: ruby-mass-assignment-permit-bang
  params.require(:settings).permit!
end

def safe_params
  # ok: ruby-mass-assignment-permit-bang
  params.require(:user).permit(:name, :email)
end
