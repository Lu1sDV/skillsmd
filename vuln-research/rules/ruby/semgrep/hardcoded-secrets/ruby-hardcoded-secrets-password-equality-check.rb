# Fixture for comparing input against a hardcoded secret with ==.
# Flagged comparisons use a literal secret; the safe check uses a constant-time compare.

class AdminGate
  def authorize(params, request)
    # ruleid: ruby-hardcoded-secrets-password-equality-check
    return :ok if params[:admin_password] == "s3cr3t-admin-pass"

    # ruleid: ruby-hardcoded-secrets-password-equality-check
    return :ok if request.headers["X-Api-Token"] == "static-api-token-value"

    # ok: ruby-hardcoded-secrets-password-equality-check
    ActiveSupport::SecurityUtils.secure_compare(params[:admin_password], ENV["ADMIN_PASSWORD"])
  end
end
