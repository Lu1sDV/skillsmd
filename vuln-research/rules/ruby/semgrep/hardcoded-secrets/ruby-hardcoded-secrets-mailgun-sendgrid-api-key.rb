# Fixture for a hardcoded SendGrid API key.
# Flagged assignment embeds an SG. key; the safe line reads it from the environment.

class MailDelivery
  def configure
    # ruleid: ruby-hardcoded-secrets-mailgun-sendgrid-api-key
    api_key = "SG.aBcDeFgHiJkLmNoPqRsTuV.wXyZ0123456789abcdefGHIJKLMNOPqrstuvWXYZ12"

    # ok: ruby-hardcoded-secrets-mailgun-sendgrid-api-key
    api_key_safe = ENV["SENDGRID_API_KEY"]
    [api_key, api_key_safe]
  end
end
