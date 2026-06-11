# Fixture for the update-params rule.

def save_settings(account)
  # ruleid: ruby-mass-assignment-update-params
  account.update(params[:account])
end

def save_settings_safe(account)
  # ok: ruby-mass-assignment-update-params
  account.update(params.require(:account).permit(:timezone, :locale))
end

def save_settings_literal(account)
  # ok: ruby-mass-assignment-update-params
  account.update(timezone: "UTC")
end
