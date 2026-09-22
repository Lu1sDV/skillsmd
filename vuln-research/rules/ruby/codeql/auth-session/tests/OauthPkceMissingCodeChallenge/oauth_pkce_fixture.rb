# Fixture for OauthPkceMissingCodeChallenge
# BAD cases: authorize_url called via auth_code without code_challenge
# GOOD cases: authorize_url called with code_challenge present

require 'oauth2'

class OAuthController
  # BAD: direct chain — no code_challenge keyword
  def connect_bad
    client = OAuth2::Client.new('id', 'secret', site: 'https://example.com')
    url = client.auth_code.authorize_url( # BAD: missing code_challenge
      redirect_uri: 'https://app.example.com/callback',
      scope: 'read',
      state: 'random_state'
    )
    redirect_to url
  end

  # GOOD: direct chain — code_challenge present (PKCE compliant)
  def connect_good
    client = OAuth2::Client.new('id', 'secret', site: 'https://example.com')
    verifier = SecureRandom.urlsafe_base64(32)
    challenge = Base64.urlsafe_encode64(
      OpenSSL::Digest::SHA256.digest(verifier), padding: false
    )
    url = client.auth_code.authorize_url( # GOOD: code_challenge supplied
      redirect_uri: 'https://app.example.com/callback',
      scope: 'read',
      state: 'random_state',
      code_challenge: challenge,
      code_challenge_method: 'S256'
    )
    session[:pkce_verifier] = verifier
    redirect_to url
  end

  # BAD: variable-indirection form — ac = client.auth_code; ac.authorize_url(...)
  def connect_bad_via_variable
    client = OAuth2::Client.new('id', 'secret', site: 'https://example.com')
    ac = client.auth_code
    url = ac.authorize_url( # BAD: missing code_challenge
      redirect_uri: 'https://app.example.com/callback',
      scope: 'write'
    )
    redirect_to url
  end

  # GOOD: variable-indirection form with code_challenge
  def connect_good_via_variable
    client = OAuth2::Client.new('id', 'secret', site: 'https://example.com')
    ac = client.auth_code
    verifier = SecureRandom.urlsafe_base64(32)
    challenge = Base64.urlsafe_encode64(
      OpenSSL::Digest::SHA256.digest(verifier), padding: false
    )
    url = ac.authorize_url( # GOOD: code_challenge supplied
      redirect_uri: 'https://app.example.com/callback',
      scope: 'write',
      code_challenge: challenge,
      code_challenge_method: 'S256'
    )
    session[:pkce_verifier] = verifier
    redirect_to url
  end
end
