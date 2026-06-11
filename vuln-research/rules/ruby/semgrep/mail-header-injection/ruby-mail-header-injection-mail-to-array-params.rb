# Fixture for the tainted recipient-list To: detector.

class BulkMailer < ApplicationMailer
  def notify_list
    # ruleid: ruby-mail-header-injection-mail-to-array-params
    mail(to: params[:recipients].join(", "), subject: "Update")
  end

  def notify_split
    # ruleid: ruby-mail-header-injection-mail-to-array-params
    mail(to: params[:recipients].split(","), subject: "Update")
  end

  def notify_list_safe
    # ok: ruby-mail-header-injection-mail-to-array-params
    mail(to: subscribers.map(&:email), subject: "Update")
  end
end
