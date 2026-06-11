# Fixture for the to-unsafe-h rule.

def all_params
  # ruleid: ruby-mass-assignment-to-unsafe-h
  attrs = params.to_unsafe_h
  User.new(attrs)
end

def filtered_params
  # ok: ruby-mass-assignment-to-unsafe-h
  attrs = params.require(:user).permit(:name).to_h
  User.new(attrs)
end
