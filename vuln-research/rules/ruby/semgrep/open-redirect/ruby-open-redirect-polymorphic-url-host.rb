# Fixture for polymorphic_url host poisoning.

class NotifierController < ApplicationController
  def notify(record)
    # ruleid: ruby-open-redirect-polymorphic-url-host
    link = polymorphic_url(record, host: params[:host])
    deliver(link)
  end

  def notify_header(record)
    # ruleid: ruby-open-redirect-polymorphic-url-host
    link = polymorphic_url(record, host: request.host)
    deliver(link)
  end

  def notify_safe(record)
    # ok: ruby-open-redirect-polymorphic-url-host
    link = polymorphic_url(record, host: "app.example.com")
    deliver(link)
  end
end
