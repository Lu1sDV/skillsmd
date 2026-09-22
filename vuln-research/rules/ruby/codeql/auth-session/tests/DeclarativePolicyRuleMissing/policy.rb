# Test fixtures for rb/auth-session-declarative-policy-rule-missing (CWE-285).
# Mirrors GitLab DeclarativePolicy access-control fixes where an ability was enabled
# without a governing rule block, leaving the permission unconditionally granted.

# BAD: `enable :read_code` is called directly in the class body — no `rule { }` gates it.
# The permission is always on regardless of repository state.
# Mirrors GitLab fix 047963e52d19 (repository_disabled rule missing for :read_code).
class ProjectPolicy < BasePolicy
  condition(:repository_disabled) { @subject.repository_access_level == :disabled }

  rule { repository_disabled }.policy do
    prevent :read_repository
  end

  enable :read_code  # BAD: ungated, no rule { } wraps this
end

# BAD: `enable :fork_project` and `enable :create_merge_request_in` are bare in the class body.
# Mirrors GitLab fix 10432c4573d1 (auditor rule missing prevent for fork/MR).
class AuditPolicy < BasePolicy
  condition(:auditor) { @user.auditor? }

  rule { auditor }.enable :access_security_and_compliance

  enable :fork_project           # BAD: ungated
  enable :create_merge_request_in  # BAD: ungated
end

# GOOD: every `enable` is chained directly on a `rule { }` call — properly gated.
class IssuePolicy < BasePolicy
  condition(:is_incident) { @subject.issue_type == :incident }
  condition(:reporter_access) { @user.access_level >= 20 }

  rule { is_incident & ~can?(:reporter_access) }.policy do
    prevent :admin_issue
    prevent :update_issue
  end

  rule { reporter_access }.enable :update_issue
  rule { ~is_incident }.enable :clone_issue
end

# GOOD: enable inside a .policy block chained on a rule — properly gated.
class MergeRequestPolicy < BasePolicy
  condition(:can_merge) { @user.can?(:merge_requests, @subject) }

  rule { can_merge }.policy do
    enable :accept_merge_request
    enable :reopen_merge_request
  end
end

# GOOD: a policy with only prevents and no bare enables — no flag.
class NotePolicy < BasePolicy
  condition(:author) { @subject.author == @user }

  rule { ~author }.prevent :edit_note
  rule { ~author }.prevent :delete_note
end
