# Fixture for the tainted Bcc: silent-recipient detector.

class InvoiceMailer < ApplicationMailer
  def send_invoice
    # ruleid: ruby-mail-header-injection-mail-bcc-params
    mail(to: client.email, bcc: params[:bcc], subject: "Invoice")
  end

  def send_invoice_safe
    # ok: ruby-mail-header-injection-mail-bcc-params
    mail(to: client.email, bcc: Rails.application.config.audit_inbox, subject: "Invoice")
  end
end
