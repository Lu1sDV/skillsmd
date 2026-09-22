class OmniauthCallbacksController < ApplicationController
  # BAD: provider and extern_uid passed as URL params — attacker can forge them
  def redirect_authorize_identity_link_bad(identity_linker)
    state = SecureRandom.uuid
    session[:identity_link_state] = state
    redirect_to new_user_settings_identities_path(
      provider: identity_linker.provider,
      extern_uid: identity_linker.uid,
      state: state
    )
  end

  # GOOD: provider and extern_uid stored in session — params cannot be forged
  def redirect_authorize_identity_link_good(identity_linker)
    state = SecureRandom.uuid
    session[:identity_link_state] = state
    session[:identity_link_provider] = identity_linker.provider
    session[:identity_link_extern_uid] = identity_linker.uid
    redirect_to new_user_settings_identities_path(state: state)
  end

  # GOOD: redirect_to with provider/extern_uid AND session assignments in same method
  def redirect_authorize_with_both(identity_linker)
    state = SecureRandom.uuid
    session[:identity_link_provider] = identity_linker.provider
    session[:identity_link_extern_uid] = identity_linker.uid
    redirect_to new_user_settings_identities_path(
      provider: identity_linker.provider,
      extern_uid: identity_linker.uid,
      state: state
    )
  end
end
