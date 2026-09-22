# Fixture for UnsafeJsonParse
# BAD cases: direct .parse without size/depth guards
class ExternalAuthResponse
  def parse_response!
    # BAD: Gitlab::Json.parse on an HTTP response body
    Gitlab::Json.parse(@response.body)
  end
end

class ErrorTrackingStrategy
  def parse_json(payload)
    # BAD: Gitlab::Json.parse on external payload
    Gitlab::Json.parse(payload)
  rescue JSON::ParserError
  end
end

class MockCiIntegration
  def read_commit_status(response)
    # BAD: bare JSON.parse on HTTP response body
    status = JSON.parse(response.body).fetch('status', nil)
    status
  rescue JSON::ParserError
  end
end

# GOOD cases: safe_parse enforces size/depth limits
class SafeExternalAuthResponse
  def parse_response!
    # GOOD: Gitlab::Json.safe_parse enforces limits
    Gitlab::Json.safe_parse(@response.body)
  end
end

class SafeErrorTrackingStrategy
  def parse_json(payload)
    # GOOD: safe_parse on external payload
    Gitlab::Json.safe_parse(payload)
  rescue JSON::ParserError
  end
end
