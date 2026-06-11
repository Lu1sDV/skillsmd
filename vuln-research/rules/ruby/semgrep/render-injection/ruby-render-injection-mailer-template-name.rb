# Fixture for a mailer template_name taken from request input.

class CampaignMailer < ApplicationMailer
  def blast
    # ruleid: ruby-render-injection-mailer-template-name
    mail(to: @user.email, template_name: params[:tpl])
  end

  def safe_blast
    # ok: ruby-render-injection-mailer-template-name
    mail(to: @user.email, template_name: "weekly_digest")
  end
end
