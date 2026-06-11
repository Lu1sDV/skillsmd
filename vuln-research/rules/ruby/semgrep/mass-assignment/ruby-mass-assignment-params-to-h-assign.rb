# Fixture for the params-to-h-assign rule.

def build_from_hash
  # ruleid: ruby-mass-assignment-params-to-h-assign
  User.new(params[:user].to_h)
end

def update_from_hash(record)
  # ruleid: ruby-mass-assignment-params-to-h-assign
  record.update(params[:record].to_h)
end

def build_from_hash_safe
  # ok: ruby-mass-assignment-params-to-h-assign
  User.new(params.require(:user).permit(:name).to_h)
end
