# Fixture for the Mechanize verify_mode disable rule.

def agent_insecure
  agent = Mechanize.new
  # ruleid: ruby-crypto-tls-mechanize-verify-none
  agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  agent
end

def agent_secure
  agent = Mechanize.new
  # ok: ruby-crypto-tls-mechanize-verify-none
  agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  agent
end
