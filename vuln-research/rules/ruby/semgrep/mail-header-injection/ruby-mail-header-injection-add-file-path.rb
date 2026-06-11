# Fixture for the add_file tainted-path attachment detector.

class DocMailer < ApplicationMailer
  def send_doc
    # ruleid: ruby-mail-header-injection-add-file-path
    attachments.add_file(params[:path])
    mail(to: recipient.email)
  end

  def send_named
    # ruleid: ruby-mail-header-injection-add-file-path
    attachments.add_file(filename: params[:name], content: blob)
    mail(to: recipient.email)
  end

  def send_doc_safe
    # ok: ruby-mail-header-injection-add-file-path
    attachments.add_file(Rails.root.join("public", "terms.pdf").to_s)
    mail(to: recipient.email)
  end
end
