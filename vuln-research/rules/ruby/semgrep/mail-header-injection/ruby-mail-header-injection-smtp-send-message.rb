# Fixture for the Net::SMTP send_message detector.

require "net/smtp"

def relay(params)
  smtp = Net::SMTP.new("localhost")
  # ruleid: ruby-mail-header-injection-smtp-send-message
  smtp.send_message(params[:raw], "noreply@example.com", "dest@example.com")
end

def relay_envelope(params)
  smtp = Net::SMTP.new("localhost")
  # ruleid: ruby-mail-header-injection-smtp-send-message
  smtp.send_message(body, params[:from], "dest@example.com")
end

def relay_safe(body)
  smtp = Net::SMTP.new("localhost")
  # ok: ruby-mail-header-injection-smtp-send-message
  smtp.send_message(body, "noreply@example.com", "dest@example.com")
end
