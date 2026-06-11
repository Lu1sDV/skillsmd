# Fixture: trusting every proxy versus pinning the real edge CIDR.

require "ipaddr"

Rails.application.configure do
  # ruleid: ruby-http-parsing-trusted-proxies-broad
  config.action_dispatch.trusted_proxies = [IPAddr.new("0.0.0.0/0")]
end

Rails.application.configure do
  # ok: ruby-http-parsing-trusted-proxies-broad
  config.action_dispatch.trusted_proxies = [IPAddr.new("10.0.0.0/24")]
end
