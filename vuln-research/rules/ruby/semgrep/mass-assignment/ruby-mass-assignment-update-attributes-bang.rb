# Fixture for the update-attributes-bang rule.

def force_edit(profile)
  # ruleid: ruby-mass-assignment-update-attributes-bang
  profile.update_attributes!(params[:profile])
end

def force_edit_safe(profile)
  # ok: ruby-mass-assignment-update-attributes-bang
  profile.update_attributes!(params.require(:profile).permit(:nickname))
end

def force_edit_literal(profile)
  # ok: ruby-mass-assignment-update-attributes-bang
  profile.update_attributes!(nickname: "x")
end
