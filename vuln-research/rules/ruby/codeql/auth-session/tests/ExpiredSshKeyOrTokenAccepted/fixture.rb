# Fixture for ExpiredSshKeyOrTokenAccepted

module API
  module Internal
    class Base
      # BAD: looks up key by fingerprint, checks nil, but never calls key.expired?
      def authorized_keys_bad(fingerprint)
        key = Key.auth.find_by_fingerprint_sha256(fingerprint)
        not_found!('Key') if key.nil?
        present key, with: Entities::SSHKey
      end

      # BAD: deploy token lookup without expired? check
      def token_auth_bad(token)
        deploy_token = DeployToken.find_by_token(token)
        not_found!('Token') if deploy_token.nil?
        sign_in(deploy_token.user)
      end

      # GOOD: looks up key and checks expired? before use
      def authorized_keys_good(fingerprint)
        key = Key.auth.find_by_fingerprint_sha256(fingerprint)
        not_found!('Key') if key.nil?
        not_found!('Key') if key.expired?
        present key, with: Entities::SSHKey
      end

      # GOOD: deploy token lookup with expired? guard
      def token_auth_good(token)
        deploy_token = DeployToken.find_by_token(token)
        not_found!('Token') if deploy_token.nil?
        not_found!('Token') if deploy_token.expired?
        sign_in(deploy_token.user)
      end
    end
  end
end
