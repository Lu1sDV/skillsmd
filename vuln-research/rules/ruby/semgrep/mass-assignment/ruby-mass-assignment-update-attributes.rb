# Fixture for the update-attributes rule.

def edit_profile(user)
  # ruleid: ruby-mass-assignment-update-attributes
  user.update_attributes(params[:user])
end

def edit_profile_safe(user)
  # ok: ruby-mass-assignment-update-attributes
  user.update_attributes(params.require(:user).permit(:bio))
end

def edit_from_literal(user)
  # ok: ruby-mass-assignment-update-attributes
  user.update_attributes(bio: "hi")
end
