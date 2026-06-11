# Fixture: disabling Host Authorization versus configuring an allowlist.

Rails.application.configure do
  # ruleid: ruby-http-parsing-hosts-clear
  config.hosts.clear
end

Rails.application.configure do
  # ok: ruby-http-parsing-hosts-clear
  config.hosts << "app.example.com"
end
