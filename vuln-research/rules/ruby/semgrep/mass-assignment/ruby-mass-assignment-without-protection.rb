# Fixture for the without-protection rule.

def build_unprotected
  # ruleid: ruby-mass-assignment-without-protection
  User.new(params[:user], without_protection: true)
end

def create_unprotected
  # ruleid: ruby-mass-assignment-without-protection
  Account.create(attrs, without_protection: true)
end

def build_protected
  # ok: ruby-mass-assignment-without-protection
  User.new(params.require(:user).permit(:name))
end
