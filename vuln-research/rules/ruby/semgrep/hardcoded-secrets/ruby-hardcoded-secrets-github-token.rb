# Fixture for a hardcoded GitHub personal access token.
# Flagged assignment embeds a ghp_ token; the safe line reads it from the environment.

class GithubClient
  def configure
    # ruleid: ruby-hardcoded-secrets-github-token
    token = "ghp_aBcDeFgHiJkLmNoPqRsTuVwXyZ0123456789"

    # ok: ruby-hardcoded-secrets-github-token
    token_safe = ENV["GITHUB_TOKEN"]
    [token, token_safe]
  end
end
