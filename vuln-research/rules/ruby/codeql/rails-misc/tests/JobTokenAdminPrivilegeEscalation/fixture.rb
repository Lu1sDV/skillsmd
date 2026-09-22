# frozen_string_literal: true

# Test fixtures for rb/rails-misc-job-token-admin-privilege-escalation (CWE-269).
# Mirrors GitLab fix b21f2bd4: condition(:admin) in BasePolicy enables admin-level
# rules without a from_ci_job_token? guard, allowing CI job tokens to gain admin access.

# BAD: policy class has a condition that gates admin rules, but no condition block
# guards against CI job tokens with from_ci_job_token?. A CI job token whose
# underlying user is an instance admin satisfies condition(:admin) and inherits
# :admin_all_resources and :manage_users.
class VulnerableBasePolicy < DeclarativePolicy::Base
  desc "User is an instance admin"
  with_options scope: :user, score: 0
  condition(:admin) do
    if Gitlab::CurrentSettings.admin_mode
      Gitlab::Auth::CurrentUserMode.new(@user).admin_mode?
    else
      @user.admin?
    end
  end

  rule { admin }.enable :admin_all_resources # BAD: no from_ci_job_token? guard anywhere
  rule { admin }.enable :manage_users        # BAD: same class, same missing guard
end

# GOOD: policy class guards with from_ci_job_token? in the condition block —
# CI job-token callers are short-circuited before admin_mode? is evaluated.
class FixedBasePolicy < DeclarativePolicy::Base
  desc "User is an instance admin"
  with_options scope: :user, score: 0
  condition(:admin) do
    next false if @user&.from_ci_job_token? # GOOD: guard present

    if Gitlab::CurrentSettings.admin_mode
      Gitlab::Auth::CurrentUserMode.new(@user).admin_mode?
    else
      @user.admin?
    end
  end

  rule { admin }.enable :admin_all_resources # GOOD: guarded by from_ci_job_token? above
  rule { admin }.enable :manage_users        # GOOD: same class, guard is present
end

# GOOD: enable call for a non-admin/non-manage ability — not the smell.
class UnrelatedPolicy < DeclarativePolicy::Base
  condition(:owner) do
    @subject.owner == @user
  end

  rule { owner }.enable :update_resource # GOOD: not an admin/manage ability
end
