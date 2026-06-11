# Fixture for a hardcoded Slack API token.
# Flagged assignment embeds an xoxb token; the safe line reads it from the environment.

class SlackNotifier
  def configure
    # ruleid: ruby-hardcoded-secrets-slack-token
    webhook_token = "xoxb-2401234567890-2409876543210-AbCdEfGhIjKlMnOpQrStUvWx"

    # ok: ruby-hardcoded-secrets-slack-token
    webhook_token_safe = ENV["SLACK_BOT_TOKEN"]
    [webhook_token, webhook_token_safe]
  end
end
