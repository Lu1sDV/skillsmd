# Fixture for hardcoded Faraday basic auth credentials.
# Flagged calls inline credentials; the safe call sources them from the environment.

class ApiConnection
  def build
    conn = Faraday.new(url: "https://api.example.com")
    # ruleid: ruby-hardcoded-secrets-faraday-basic-auth
    conn.request :basic_auth, "api-user", "h4rdcoded-faraday-pass"

    # ok: ruby-hardcoded-secrets-faraday-basic-auth
    conn.basic_auth(ENV["API_USER"], ENV["API_PASS"])
    conn
  end
end
