# Fixture for hardcoded SMTP password in Action Mailer settings.
# Flagged assignment inlines the mail password; the safe line reads it from the environment.

Rails.application.configure do
  # ruleid: ruby-hardcoded-secrets-smtp-password
  config.action_mailer.smtp_settings = { address: "smtp.example.com", user_name: "mailer@example.com", password: "Mailer-PlainText-Pass-123" }

  # ok: ruby-hardcoded-secrets-smtp-password
  config.action_mailer.smtp_settings = { address: "smtp.example.com", user_name: "mailer@example.com", password: ENV["SMTP_PASSWORD"] }
end
