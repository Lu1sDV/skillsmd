# Fixtures for UnguardedHttpResponseParsing
# BAD: inherits HTTParty::Parser, overrides `json` with size limits, but no `parse` override.
# A malicious server can return JSON with Content-Type: text/plain and bypass the size guard.
module Gitlab
  class HttpResponseParser < HTTParty::Parser # BAD: no `parse` override
    def json
      validate_response_size!(:json)
      ::JSON.parse(body)
    end

    private

    def validate_response_size!(type)
      raise "Response too large" if body.length > 10_000_000
    end
  end
end

# GOOD: same class but also overrides `parse` to detect JSON-like bodies regardless of Content-Type.
module Gitlab
  class SafeHttpResponseParser < HTTParty::Parser # GOOD: has `parse` override
    def parse
      return json if !supports_format? && body_looks_like_json?
      super
    end

    def json
      validate_response_size!(:json)
      ::JSON.parse(body)
    end

    private

    def validate_response_size!(type)
      raise "Response too large" if body.length > 10_000_000
    end

    def body_looks_like_json?
      return false if body.nil? || body.empty?
      body.match?(/\A\s*[\[{]/)
    end
  end
end
