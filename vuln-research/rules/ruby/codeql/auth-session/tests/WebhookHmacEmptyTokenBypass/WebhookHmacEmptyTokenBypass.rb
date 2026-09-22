require 'openssl'

# ---------------------------------------------------------------------------
# BAD: webhook HMAC computed without a prior blank/empty check on the token.
# If project.external_webhook_token is nil or "", HMAC("") is deterministic
# and trivially forgeable.
# ---------------------------------------------------------------------------

module Api
  class ProjectMirrorBad
    def valid_github_signature? # BAD: no token.empty? guard before HMAC
      token        = project.external_webhook_token.to_s
      payload_body = request.body.read
      signature    = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), token, payload_body)
      Rack::Utils.secure_compare(signature, request.headers['X-Hub-Signature'])
    end

    def verify_webhook_signature # BAD: bare HMAC.digest variant, no empty guard
      token  = webhook_secret.to_s
      digest = OpenSSL::HMAC.digest('sha256', token, request_body)
      ActiveSupport::SecurityUtils.secure_compare(digest, expected_digest)
    end
  end
end

# ---------------------------------------------------------------------------
# GOOD: empty-token guard added before the HMAC computation.
# ---------------------------------------------------------------------------

module Api
  class ProjectMirrorGood
    def valid_github_signature? # GOOD: returns false when token is blank
      token = project.external_webhook_token.to_s
      return false if token.empty?

      request.body.rewind
      payload_body = request.body.read
      signature    = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), token, payload_body)
      Rack::Utils.secure_compare(signature, request.headers['X-Hub-Signature'])
    end

    def verify_webhook_signature # GOOD: blank? guard covers nil+empty
      token = webhook_secret.to_s
      return false if token.blank?

      digest = OpenSSL::HMAC.digest('sha256', token, request_body)
      ActiveSupport::SecurityUtils.secure_compare(digest, expected_digest)
    end
  end
end
