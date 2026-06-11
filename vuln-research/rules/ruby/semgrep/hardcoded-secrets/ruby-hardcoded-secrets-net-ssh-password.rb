# Fixture for hardcoded Net::SSH password.
# Flagged call inlines the SSH password; the safe call sources it from the environment.

class Deployer
  def connect
    # ruleid: ruby-hardcoded-secrets-net-ssh-password
    Net::SSH.start("app.internal", "deploy", password: "Deploy!PlainPass2024", port: 22)
  end

  def connect_safe
    # ok: ruby-hardcoded-secrets-net-ssh-password
    Net::SSH.start("app.internal", "deploy", password: ENV["SSH_PASSWORD"], port: 22)
  end
end
