# Test fixtures for rb/auth-session-declarative-policy-unused-condition (CWE-285).
# Mirrors GitLab DeclarativePolicy access-control fixes where a condition was declared
# but never wired into any rule, leaving the intended access restriction absent.

# BAD: `reporter` condition is declared but no rule { reporter } exists in this class.
# The missing rule means the reporter-level access restriction was never enforced.
# Mirrors GitLab fixes 047963e52d19, 10432c4573d1 (condition declared, rule absent).
class ProjectPolicy < BasePolicy
  condition(:owner) { @user.owner? }             # GOOD – used below
  condition(:guest)  { @user.access_level >= 10 } # GOOD – used below
  condition(:reporter) { @user.access_level >= 20 } # BAD – never referenced in any rule

  rule { owner }.enable :admin_project
  rule { guest }.enable :read_project
  # reporter condition is declared but no rule references it — the access rule is missing
end

# GOOD: every declared condition is referenced in at least one rule.
class IssuePolicy < BasePolicy
  condition(:is_incident) { @subject.issue_type == :incident }
  condition(:reporter_access) { @user.access_level >= 20 }

  rule { is_incident & ~can?(:reporter_access) }.policy do
    prevent :admin_issue
  end
  rule { reporter_access }.enable :update_issue
end

# GOOD: a policy that declares and uses a single condition — no flag.
class NotePolicy < BasePolicy
  condition(:author) { @subject.author == @user }

  rule { ~author }.prevent :edit_note
end

# BAD: two unused conditions in the same class — both should be flagged.
class SnippetPolicy < BasePolicy
  condition(:public_snippet) { @subject.visibility == "public" }  # BAD – unused
  condition(:owner_snippet)  { @subject.author == @user }          # BAD – unused
  condition(:admin_user)     { @user.admin? }                      # GOOD – used below

  rule { admin_user }.enable :admin_snippet
  # public_snippet and owner_snippet are declared but no rules reference them
end
