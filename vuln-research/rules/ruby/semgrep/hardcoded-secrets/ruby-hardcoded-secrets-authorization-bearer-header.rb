# Fixture for a hardcoded Authorization header token.
# Flagged header inlines a Bearer token; the safe header interpolates an env-sourced value.

class ApiCaller
  def headers
    # ruleid: ruby-hardcoded-secrets-authorization-bearer-header
    { "Authorization" => "Bearer eyJhbGciOiJIUzI1NiJ9.fixed.token-value-1234" }
  end

  def headers_safe
    # ok: ruby-hardcoded-secrets-authorization-bearer-header
    { "Authorization" => "Bearer #{ENV['API_BEARER_TOKEN']}" }
  end
end
