# Fixture for the params.permit! over-permissive mass-assignment detector.

def open_update
  # ruleid: ruby-auth-session-params-permit-bang
  user.update(params.permit!)
end

def scoped_update
  # ok: ruby-auth-session-params-permit-bang
  user.update(params.require(:user).permit(:name, :email))
end
