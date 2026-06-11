# Fixture for the update-bang-params rule.

def force_save(subscription)
  # ruleid: ruby-mass-assignment-update-bang-params
  subscription.update!(params[:subscription])
end

def force_save_safe(subscription)
  # ok: ruby-mass-assignment-update-bang-params
  subscription.update!(params.require(:subscription).permit(:tier))
end

def force_save_literal(subscription)
  # ok: ruby-mass-assignment-update-bang-params
  subscription.update!(tier: "free")
end
