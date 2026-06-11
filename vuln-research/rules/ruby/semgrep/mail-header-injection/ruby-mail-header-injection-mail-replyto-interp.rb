# Fixture for the interpolated Reply-To header detector.

class SupportMailer < ApplicationMailer
  def respond
    # ruleid: ruby-mail-header-injection-mail-replyto-interp
    mail(to: customer.email, reply_to: "#{params[:reply]}", subject: "Re: ticket")
  end

  def respond_safe
    # ok: ruby-mail-header-injection-mail-replyto-interp
    mail(to: customer.email, reply_to: agent.verified_email, subject: "Re: ticket")
  end
end
