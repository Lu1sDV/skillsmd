# Fixture for the attachment filename header injection detector.

class ExportMailer < ApplicationMailer
  def deliver_export
    # ruleid: ruby-mail-header-injection-attachment-filename
    attachments[params[:filename]] = File.read(report_path)
    mail(to: owner.email)
  end

  def deliver_interp
    # ruleid: ruby-mail-header-injection-attachment-filename
    attachments["report-#{params[:id]}.csv"] = csv_blob
    mail(to: owner.email)
  end

  def deliver_export_safe
    # ok: ruby-mail-header-injection-attachment-filename
    attachments["report.csv"] = File.read(report_path)
    mail(to: owner.email)
  end
end
