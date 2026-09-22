# frozen_string_literal: true

# BAD: class_eval on DeviceAuthorizationRequest without any scope validate call —
#      the device flow can issue tokens for scopes beyond what the app was approved for.
if defined?(Doorkeeper::DeviceAuthorizationGrant::OAuth::DeviceAuthorizationRequest)
  Doorkeeper::DeviceAuthorizationGrant::OAuth::DeviceAuthorizationRequest.class_eval do # BAD: no validate :scopes_match_configured
    private

    def validate_access
      true
    end
  end
end

# GOOD: class_eval on DeviceAuthorizationRequest WITH a scope validate call —
#       the fixed version adds validate :scopes_match_configured to enforce scope checks.
if defined?(Doorkeeper::DeviceAuthorizationGrant::OAuth::DeviceAuthorizationRequest)
  Doorkeeper::DeviceAuthorizationGrant::OAuth::DeviceAuthorizationRequest.class_eval do
    validate :scopes_match_configured, error: Doorkeeper::Errors::InvalidScope # GOOD: scope validation present

    private

    def validate_scopes_match_configured
      return false if scopes.blank?

      Doorkeeper::OAuth::Helpers::ScopeChecker.valid?(
        scope_str: scopes.to_s,
        server_scopes: server.scopes,
        app_scopes: client.scopes,
        grant_type: Doorkeeper::DeviceAuthorizationGrant::OAuth::DEVICE_CODE
      )
    end
  end
end
