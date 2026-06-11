# Fixture for the bulk headers() assignment detector.

class BroadcastMailer < ApplicationMailer
  def announce
    # ruleid: ruby-mail-header-injection-headers-bulk
    headers(params[:headers])
    mail(to: list.email)
  end

  def announce_safe
    # ok: ruby-mail-header-injection-headers-bulk
    headers({ "X-Source" => "broadcast" })
    mail(to: list.email)
  end
end
