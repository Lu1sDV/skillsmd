# Fixture for hardcoded AWS access key id.
# The flagged assignment embeds an AKIA-format key; the safe line reads it from config.

class AwsClient
  def configure
    # ruleid: ruby-hardcoded-secrets-aws-access-key-id
    access_key = "AKIAIOSFODNN7EXAMPLE"

    # ok: ruby-hardcoded-secrets-aws-access-key-id
    access_key_safe = ENV["AWS_ACCESS_KEY_ID"]
    [access_key, access_key_safe]
  end
end
