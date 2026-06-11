# Fixture for hardcoded Net::HTTP basic auth credentials.
# Flagged call inlines username/password; the safe call sources both from the environment.

class UpstreamClient
  def fetch(uri)
    req = Net::HTTP::Get.new(uri)
    # ruleid: ruby-hardcoded-secrets-net-http-basic-auth
    req.basic_auth("service-account", "Pl4inTextServicePass")

    # ok: ruby-hardcoded-secrets-net-http-basic-auth
    req.basic_auth(ENV["UPSTREAM_USER"], ENV["UPSTREAM_PASS"])
    req
  end
end
