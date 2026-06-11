# Fixture for the inline attachment name header injection detector.

class NewsletterMailer < ApplicationMailer
  def issue
    # ruleid: ruby-mail-header-injection-inline-attachment-name
    attachments.inline[params[:logo]] = logo_blob
    mail(to: subscriber.email)
  end

  def issue_interp
    # ruleid: ruby-mail-header-injection-inline-attachment-name
    attachments.inline["banner-#{params[:id]}.png"] = banner_blob
    mail(to: subscriber.email)
  end

  def issue_safe
    # ok: ruby-mail-header-injection-inline-attachment-name
    attachments.inline["logo.png"] = logo_blob
    mail(to: subscriber.email)
  end
end
