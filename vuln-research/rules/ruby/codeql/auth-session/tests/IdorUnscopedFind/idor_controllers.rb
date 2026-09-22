# Test fixtures for rb/auth-session-idor-unscoped-find (CWE-639).
# BAD cases must be flagged; GOOD cases must NOT be flagged.

class ProjectsController < ApplicationController
  # BAD: bare constant receiver + params argument — classic IDOR (grounded in
  # GitLab fix 126fe92ee748 / 4c696f6b4c44: ComplianceManagement::Framework.find).
  def show
    @project = Project.find(params[:id])
  end

  # BAD: find_by with a hash keyword whose value comes from params.
  # Grounded in GitLab oracle pattern (unscoped find_by on model class).
  def edit
    @issue = Issue.find_by(id: params[:issue_id])
  end

  # GOOD: receiver is a method-call chain (current_user association), not a
  # bare constant — the lookup is scoped to the current user's records.
  def safe_show
    @project = current_user.projects.find(params[:id])
  end

  # GOOD: bare constant receiver but argument is NOT from params — no IDOR risk
  # from request parameters.
  def by_token
    @project = Project.find(some_local_token)
  end
end
