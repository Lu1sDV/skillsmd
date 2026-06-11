# Fixture for the privileged-setter rule.

def promote(user)
  # ruleid: ruby-mass-assignment-privileged-setter
  user.admin = params[:admin]
end

def reassign(record)
  # ruleid: ruby-mass-assignment-privileged-setter
  record.account_id = params[:account_id]
end

def promote_safe(user)
  # ok: ruby-mass-assignment-privileged-setter
  user.admin = current_user.superadmin?
end

def assign_owner_safe(record)
  # ok: ruby-mass-assignment-privileged-setter
  record.account_id = current_account.id
end
