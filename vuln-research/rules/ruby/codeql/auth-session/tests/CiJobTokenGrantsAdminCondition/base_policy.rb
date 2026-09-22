# Test fixtures for rb/auth-session-ci-job-token-grants-admin-condition (CWE-269).
# Mirrors GitLab fix f5e8c0286f02: condition(:admin) in BasePolicy checks admin_mode?
# without first guarding against CI job-token callers via from_ci_job_token?.

# BAD: condition(:admin) calls admin_mode? with no from_ci_job_token? guard.
# A CI job token whose underlying user is an instance admin satisfies this condition
# and inherits admin-level permissions — privilege escalation.
class BasePolicy < DeclarativePolicy::Base
  desc "User is an instance admin"
  with_options scope: :user, score: 0
  condition(:admin) do
    if Gitlab::CurrentSettings.admin_mode
      Gitlab::Auth::CurrentUserMode.new(@user).admin_mode?
    else
      @user.admin?
    end
  end

  rule { admin }.enable :admin_all_resources
end

# GOOD: condition(:admin) guards with from_ci_job_token? first — job-token callers
# are short-circuited before admin_mode? is evaluated.
class FixedBasePolicy < DeclarativePolicy::Base
  desc "User is an instance admin"
  with_options scope: :user, score: 0
  condition(:admin) do
    next false if @user&.from_ci_job_token?

    if Gitlab::CurrentSettings.admin_mode
      Gitlab::Auth::CurrentUserMode.new(@user).admin_mode?
    else
      @user.admin?
    end
  end

  rule { admin }.enable :admin_all_resources
end

# BAD: condition(:is_admin) variant — same smell, different symbol name.
class SomeOtherPolicy < DeclarativePolicy::Base
  condition(:is_admin) do
    @user.admin?
  end

  rule { is_admin }.enable :manage_everything
end

# GOOD: condition(:admin) that has no admin-mode check at all — not the smell.
class UnrelatedPolicy < DeclarativePolicy::Base
  condition(:admin) do
    @subject.owner == @user
  end

  rule { admin }.enable :manage_subject
end
