# Fixture for the permit-all-config rule.

def configure_loose
  # ruleid: ruby-mass-assignment-permit-all-config
  ActionController::Parameters.permit_all_parameters = true
end

def configure_strict
  # ok: ruby-mass-assignment-permit-all-config
  ActionController::Parameters.action_on_unpermitted_parameters = :raise
end
