# Fixture for the tainted SMTP relay configuration detector.

def configure_outbound(params, message)
  # ruleid: ruby-mail-header-injection-smtp-settings-host
  message.delivery_method(:smtp, address: params[:smtp_host], port: 587)
  message
end

def configure_outbound_safe(message)
  # ok: ruby-mail-header-injection-smtp-settings-host
  message.delivery_method(:smtp, address: "smtp.example.com", port: 587)
  message
end
