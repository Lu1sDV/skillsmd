# Fixture for PatDisabledPolicyNotEnforcedInFinder
# Tests that find_by_token overrides missing enterprise-group PAT-disabled checks are flagged.

module EE
  module PersonalAccessToken
    extend ActiveSupport::Concern

    class_methods do
      # BAD: checks only instance-level personal_access_tokens_disabled? but never
      # verifies enterprise_user? / disable_personal_access_tokens? for the group.
      def find_by_token(token)
        return if ::Gitlab::CurrentSettings.personal_access_tokens_disabled?

        super
      end

      # GOOD: also checks enterprise-group-level disable_personal_access_tokens? flag.
      def find_by_token_safe(token)
        return if ::Gitlab::CurrentSettings.personal_access_tokens_disabled?

        pat_token = super

        disabled_by_group = pat_token&.user&.enterprise_user? &&
          pat_token.user.enterprise_group.disable_personal_access_tokens?
        return if disabled_by_group

        pat_token
      end
    end
  end
end
