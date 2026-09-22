# frozen_string_literal: true

# ---------------------------------------------------------------------------
# BAD: GroupAccessTokens::RotateService subclass inherits from
# PersonalAccessTokens::RotateService but never overrides valid_access_level?,
# so the default implementation (returns true) is used.  Any caller can rotate
# a group access token to an access level exceeding their own role.
# ---------------------------------------------------------------------------
module PersonalAccessTokens
  class RotateService # base — default valid_access_level? returns true
    def execute(params = {})
      return error_response("Not eligible") unless valid_access_level?

      # ... rotate token ...
    end

    private

    def valid_access_level?
      true # BAD default — subclasses must override
    end
  end
end

module GroupAccessTokens
  # BAD: inherits RotateService, no valid_access_level? override
  class RotateService < ::PersonalAccessTokens::RotateService # $ ALERT
  end
end

# ---------------------------------------------------------------------------
# GOOD: ProjectAccessTokens::RotateService overrides valid_access_level? and
# checks both caller and token-owner role via max_member_access_for_user.
# ---------------------------------------------------------------------------
module ProjectAccessTokens
  class RotateService < ::PersonalAccessTokens::RotateService
    private

    def valid_access_level?
      return true if current_user.can_admin_all_resources?

      token_access_level = project.team.max_member_access(token.user.id).to_i
      current_user_access_level = project.team.max_member_access(current_user.id).to_i

      token_access_level <= current_user_access_level
    end
  end
end
