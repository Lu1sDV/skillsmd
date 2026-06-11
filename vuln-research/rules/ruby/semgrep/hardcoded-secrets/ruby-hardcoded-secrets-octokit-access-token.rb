# Fixture for hardcoded Octokit access token.
# Flagged call inlines the token; the safe call sources it from the environment.

class RepoSync
  def client
    # ruleid: ruby-hardcoded-secrets-octokit-access-token
    Octokit::Client.new(access_token: "ghp_hardcodedOctokitToken0123456789abcd")
  end

  def client_safe
    # ok: ruby-hardcoded-secrets-octokit-access-token
    Octokit::Client.new(access_token: ENV["GITHUB_TOKEN"])
  end
end
