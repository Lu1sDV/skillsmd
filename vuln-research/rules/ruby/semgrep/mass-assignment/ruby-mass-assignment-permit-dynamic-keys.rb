# Fixture for the permit-dynamic-keys rule.

def loose_params
  # ruleid: ruby-mass-assignment-permit-dynamic-keys
  params.require(:user).permit(*params.keys)
end

def loose_params_array
  # ruleid: ruby-mass-assignment-permit-dynamic-keys
  params.require(:user).permit(params.keys)
end

def tight_params
  # ok: ruby-mass-assignment-permit-dynamic-keys
  params.require(:user).permit(:name, :email)
end
