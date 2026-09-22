# Test fixtures for rb/auth-session-missing-can-check-in-service (CWE-862).

# BAD: execute method calls save! referencing current_user but has no can? check —
# mirrors the GitLab service pattern where authz guard was missing (caff25a44006).
class UpdateProjectService
  def execute
    project.owner = current_user
    project.save!
  end

  private

  def project
    @project
  end

  def current_user
    @current_user
  end
end

# BAD: execute method calls destroy! and create! without can? guard —
# mirrors the pattern where a token rotation service mutates without checking permissions.
class RotateTokenService
  def execute(token)
    token.destroy!
    Token.create!(user: current_user)
  end

  private

  def current_user
    @current_user
  end
end

# GOOD: execute method calls save! and has can?(current_user, ...) guard.
class SafeUpdateProjectService
  def execute
    return error('Access denied', :unauthorized) unless can?(current_user, :admin_project, project)

    project.owner = current_user
    project.save!
  end

  private

  def project
    @project
  end

  def current_user
    @current_user
  end
end

# GOOD: execute method calls destroy but checks Ability.allowed?(current_user, :delete_token, token).
class SafeRotateTokenService
  def execute(token)
    return unless Ability.allowed?(current_user, :delete_token, token)

    token.destroy!
    Token.create!(user: current_user)
  end

  private

  def current_user
    @current_user
  end
end

# GOOD: execute method with no current_user reference — background job, not flagged.
class BackgroundCleanupService
  def execute
    OldRecord.delete_all
  end
end

# GOOD: not a *Service/*Finder/*Resolver class — ordinary class, not flagged.
class ProjectUpdater
  def execute
    @project.save!
  end

  def current_user
    @current_user
  end
end
