# Test fixtures for rb/auth-session-ci-job-token-scope-bypass (CWE-863).
# Mirrors GitLab fix 2aa664777ba2: CI job token accepted but no scope guard
# (project_allowed_for_job_token? / allowed_for_job_token? / scoped_to?) present.

module API
  class Projects < Grape::API::Instance
    # BAD: authenticates via job token, then accesses the project with no scope guard.
    # A token issued for project A can reach project B when inbound scope is enabled.
    def find_project_unsafe
      authenticate_jobtoken!
      project = find_project!(params[:id])
      project
    end

    # BAD: legacy method name variant — also flagged.
    def find_project_unsafe2
      authenticate_job_token!
      project = find_project!(params[:id])
      project
    end

    # GOOD: authenticates via job token AND calls the scope guard before granting access.
    def find_project_safe
      authenticate_jobtoken!
      project = find_project!(params[:id])
      forbidden! unless project_allowed_for_job_token?(project)
      project
    end

    # GOOD: uses allowed_for_job_token? guard — also suppresses the finding.
    def find_project_safe2
      authenticate_job_token!
      project = find_project!(params[:id])
      raise ForbiddenError unless allowed_for_job_token?(project)
      project
    end

    # GOOD: uses scoped_to? guard.
    def find_project_safe3
      authenticate_jobtoken!
      project = find_project!(params[:id])
      ci_job_token.scoped_to?(project)
      project
    end
  end
end
