# Fixture for hardcoded OmniAuth provider client id/secret.
# Flagged provider line inlines literals; the safe provider reads them from the environment.

Rails.application.config.middleware.use OmniAuth::Builder do
  # ruleid: ruby-hardcoded-secrets-omniauth-client-secret
  provider :google_oauth2, "1234567890-abcdefg.apps.googleusercontent.com", "GOCSPX-aBcDeFgHiJkLmNoPqRsTuV"

  # ok: ruby-hardcoded-secrets-omniauth-client-secret
  provider :google_oauth2, ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"]
end
