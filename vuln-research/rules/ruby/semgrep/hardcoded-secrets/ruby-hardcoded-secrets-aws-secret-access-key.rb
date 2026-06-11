# Fixture for hardcoded AWS secret access key passed to the SDK credential object.
# Flagged calls inline the secret; the safe call sources both parts from the environment.

class AwsCreds
  def build
    # ruleid: ruby-hardcoded-secrets-aws-secret-access-key
    Aws::Credentials.new("AKIAIOSFODNN7EXAMPLE", "wJalrXUtnFEMIK7MDENGbPxRfiCYEXAMPLEKEY")
  end

  def build_mixed
    # ruleid: ruby-hardcoded-secrets-aws-secret-access-key
    Aws::Credentials.new(ENV["AWS_ACCESS_KEY_ID"], "wJalrXUtnFEMIK7MDENGbPxRfiCYEXAMPLEKEY")
  end

  def build_safe
    # ok: ruby-hardcoded-secrets-aws-secret-access-key
    Aws::Credentials.new(ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_ACCESS_KEY"])
  end
end
