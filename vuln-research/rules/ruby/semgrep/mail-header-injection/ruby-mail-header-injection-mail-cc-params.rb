# Fixture for the tainted Cc: recipient header detector.

class ReportMailer < ApplicationMailer
  def digest
    # ruleid: ruby-mail-header-injection-mail-cc-params
    mail(to: owner.email, cc: params[:cc], subject: "Digest")
  end

  def digest_safe
    # ok: ruby-mail-header-injection-mail-cc-params
    mail(to: owner.email, cc: team.approved_emails, subject: "Digest")
  end
end
