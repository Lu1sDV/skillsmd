# Fixture for the tainted From: header detector.

class ContactMailer < ApplicationMailer
  def relay
    # ruleid: ruby-mail-header-injection-mail-from-params
    mail(to: "support@example.com", from: params[:sender], subject: "Contact")
  end

  def relay_safe
    # ok: ruby-mail-header-injection-mail-from-params
    mail(to: "support@example.com", from: "noreply@example.com", subject: "Contact")
  end
end
