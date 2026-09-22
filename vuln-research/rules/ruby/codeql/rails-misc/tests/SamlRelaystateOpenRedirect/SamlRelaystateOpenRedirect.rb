# Fixture for SamlRelaystateOpenRedirect
# BAD cases: params['RelayState'] / params[:RelayState] passed to a redirect
#            sink with no origin-validation guard in the same method.
# GOOD cases: origin-validation guard present before using RelayState.

module OmniAuth
  class CallbacksController
    # BAD: passes params['RelayState'] to safe_redirect_path without
    #      calling valid_gitlab_initiated_saml_request? first.
    def saml_redirect_path_bad
      safe_redirect_path(params['RelayState']) || "/dashboard" # BAD: no origin guard
    end

    # BAD: symbol key variant — params[:RelayState] also unguarded.
    def saml_redirect_symbol_bad
      safe_redirect_path(params[:RelayState]) || "/dashboard" # BAD: symbol key, no guard
    end

    # GOOD: origin validated before the redirect sink is reached.
    def saml_redirect_path_good
      return unless valid_gitlab_initiated_saml_request?
      safe_redirect_path(params['RelayState']) || "/dashboard" # GOOD: guard present
    end

    # GOOD: uses gitlab_initiated? directly (the lower-level guard).
    def saml_redirect_path_good2
      return unless gitlab_initiated?(saml_response)
      safe_redirect_path(params['RelayState']) || "/dashboard" # GOOD: guard present
    end
  end
end
