# Fixture for PasskeyWebauthnVerifyReturnUnchecked
# BAD cases: verify_passkey / verify_webauthn called as bare statements (return value discarded)
# GOOD cases: return value is consumed (raise-unless, assignment, or conditional)

module Authn
  module Passkey
    class AuthenticateService
      def execute
        encoder = WebAuthn.configuration.encoder

        # BAD: return value of verify_passkey is discarded — if lib returns false, auth continues
        verify_passkey(@stored_passkey_credential, passkey_credential, @challenge, encoder)

        @stored_passkey_credential.update!(counter: passkey_credential.sign_count)
        success
      end
    end
  end

  module WebAuthn
    class AuthenticateService
      def execute
        encoder = WebAuthn.configuration.encoder

        # BAD: return value of verify_webauthn is discarded
        verify_webauthn(stored_webauthn_credential, webauthn_credential, @challenge, encoder)

        stored_webauthn_credential.update!(counter: webauthn_credential.sign_count)
        success
      end
    end
  end
end

module Fixed
  module Passkey
    class AuthenticateService
      def execute
        encoder = WebAuthn.configuration.encoder

        # GOOD: raise unless guards on the return value — auth aborts if verify_passkey returns false
        raise WebAuthn::Error unless verify_passkey(@stored_passkey_credential, passkey_credential, @challenge, encoder)

        @stored_passkey_credential.update!(counter: passkey_credential.sign_count)
        success
      end
    end
  end

  module WebAuthn
    class AuthenticateService
      def execute
        encoder = WebAuthn.configuration.encoder

        # GOOD: return value checked via assignment and conditional
        result = verify_webauthn(stored_webauthn_credential, webauthn_credential, @challenge, encoder)
        raise WebAuthn::Error unless result

        stored_webauthn_credential.update!(counter: webauthn_credential.sign_count)
        success
      end
    end
  end
end
