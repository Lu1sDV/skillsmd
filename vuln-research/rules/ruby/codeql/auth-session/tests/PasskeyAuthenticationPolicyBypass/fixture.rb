# Fixtures for PasskeyAuthenticationPolicyBypass
# Tests that verify_passkey / verify_webauthn without allow_passkey_authentication? is flagged.

module Authn
  module Passkey
    class AuthenticateService
      def execute
        encoder = WebAuthn.configuration.encoder
        passkey_credential = WebAuthn::PublicKeyCredential::AuthenticationResponse.from_get(params)

        # BAD: verify_passkey is called and its return is checked, but there is no
        # allow_passkey_authentication? policy guard in this method.
        raise WebAuthn::Error unless verify_passkey(@stored_passkey_credential, passkey_credential, @challenge, encoder)

        @stored_passkey_credential.update!(counter: passkey_credential.sign_count, last_used_at: Time.current)

        ServiceResponse.success(
          message: 'Passkey successfully authenticated.',
          payload: find_matching_user_with_passkey(@stored_passkey_credential)
        )
      rescue WebAuthn::Error => err
        ServiceResponse.error(message: err.message)
      end
    end
  end
end

module Webauthn
  class AuthenticateService
    def execute
      encoder = WebAuthn.configuration.encoder
      webauthn_credential = WebAuthn::PublicKeyCredential::AuthenticationResponse.from_get(params)

      # BAD: verify_webauthn is called but allow_passkey_authentication? is never checked.
      raise WebAuthn::Error unless verify_webauthn(stored_webauthn_credential, webauthn_credential, @challenge, encoder)

      stored_webauthn_credential.update!(counter: webauthn_credential.sign_count, last_used_at: Time.current)

      ServiceResponse.success(message: 'WebAuthn authenticated.', payload: @user)
    rescue WebAuthn::Error => err
      ServiceResponse.error(message: err.message)
    end
  end
end

# ---------------------------------------------------------------------------
# GOOD: verify_passkey IS followed by an allow_passkey_authentication? check.
# ---------------------------------------------------------------------------

module Authn
  module Passkey
    class AuthenticateServiceFixed
      def execute
        encoder = WebAuthn.configuration.encoder
        passkey_credential = WebAuthn::PublicKeyCredential::AuthenticationResponse.from_get(params)

        raise WebAuthn::Error unless verify_passkey(@stored_passkey_credential, passkey_credential, @challenge, encoder)

        @user = find_matching_user_with_passkey(@stored_passkey_credential)

        # GOOD: policy guard present — no finding expected.
        raise WebAuthn::Error unless @user.allow_passkey_authentication?

        @stored_passkey_credential.update!(counter: passkey_credential.sign_count, last_used_at: Time.current)

        ServiceResponse.success(message: 'Passkey successfully authenticated.', payload: @user)
      rescue WebAuthn::Error => err
        ServiceResponse.error(message: err.message)
      end
    end
  end
end

module Webauthn
  class AuthenticateServiceFixed
    def execute
      encoder = WebAuthn.configuration.encoder
      webauthn_credential = WebAuthn::PublicKeyCredential::AuthenticationResponse.from_get(params)

      raise WebAuthn::Error unless verify_webauthn(stored_webauthn_credential, webauthn_credential, @challenge, encoder)

      # GOOD: passkey policy guard present — no finding expected.
      raise WebAuthn::Error if stored_webauthn_credential.passkey? && !@user.allow_passkey_authentication?

      stored_webauthn_credential.update!(counter: webauthn_credential.sign_count, last_used_at: Time.current)

      ServiceResponse.success(message: 'WebAuthn authenticated.', payload: @user)
    rescue WebAuthn::Error => err
      ServiceResponse.error(message: err.message)
    end
  end
end
