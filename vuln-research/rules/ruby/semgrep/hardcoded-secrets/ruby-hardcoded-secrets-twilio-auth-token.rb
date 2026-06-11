# Fixture for hardcoded Twilio account SID and auth token.
# Flagged call inlines both credentials; the safe call sources them from the environment.

class SmsSender
  def client
    # ruleid: ruby-hardcoded-secrets-twilio-auth-token
    Twilio::REST::Client.new("ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", "your_auth_token_abcdef0123456789")
  end

  def client_safe
    # ok: ruby-hardcoded-secrets-twilio-auth-token
    Twilio::REST::Client.new(ENV["TWILIO_SID"], ENV["TWILIO_AUTH_TOKEN"])
  end
end
