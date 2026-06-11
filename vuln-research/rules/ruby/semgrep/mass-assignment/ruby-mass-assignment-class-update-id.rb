# Fixture for the class-update-id rule.

def bulk_edit
  # ruleid: ruby-mass-assignment-class-update-id
  User.update(params[:id], params[:user])
end

def bulk_edit_safe
  # ok: ruby-mass-assignment-class-update-id
  current_user.update(params.require(:user).permit(:name))
end

def bulk_edit_scoped
  # ok: ruby-mass-assignment-class-update-id
  current_account.users.find(params[:id]).update(name: "x")
end
