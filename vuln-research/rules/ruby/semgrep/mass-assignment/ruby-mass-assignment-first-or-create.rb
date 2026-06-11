# Fixture for the first-or-create rule.

def find_or_make
  # ruleid: ruby-mass-assignment-first-or-create
  Profile.where(user_id: current_user.id).first_or_create(params[:profile])
end

def find_or_init
  # ruleid: ruby-mass-assignment-first-or-create
  Profile.where(user_id: current_user.id).first_or_initialize(params[:profile])
end

def find_or_make_safe
  attrs = params.require(:profile).permit(:bio)
  # ok: ruby-mass-assignment-first-or-create
  Profile.where(user_id: current_user.id).first_or_create(attrs)
end
