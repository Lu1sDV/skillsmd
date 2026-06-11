# Fixture for the custom mail header hash-key detector.

class AlertMailer < ApplicationMailer
  def page
    # ruleid: ruby-mail-header-injection-mail-custom-header-hash
    mail(to: oncall.email, "X-Alert-Source" => params[:source])
  end

  def page_interp
    # ruleid: ruby-mail-header-injection-mail-custom-header-hash
    mail(to: oncall.email, "X-Alert-Id" => "alert-#{params[:id]}")
  end

  def page_safe
    # ok: ruby-mail-header-injection-mail-custom-header-hash
    mail(to: oncall.email, "X-Alert-Source" => "monitoring")
  end
end
